# frozen_string_literal: true

class IssuableFinder
  class Params < SimpleDelegator
    include Gitlab::Utils::StrongMemoize

    # This is used as a common filter for None / Any / Upcoming / Started
    FILTER_NONE = 'none'
    FILTER_ANY = 'any'
    FILTER_STARTED = 'started'
    FILTER_UPCOMING = 'upcoming'

    # This is used in unassigning users
    NONE = '0'

    alias_method :params, :__getobj__

    attr_accessor :current_user, :klass

    def initialize(params, current_user, klass)
      @current_user = current_user
      @klass = klass
      # We turn the params into a HashWithIndifferentAccess. We must use #to_h first because sometimes
      # we get ActionController::Params and IssuableFinder::Params objects here.
      super(params.to_h.with_indifferent_access)
    end

    def present?
      params.present?
    end

    def milestones?
      params[:milestone_title].present? || params[:milestone_wildcard_id].present?
    end

    def filter_by_no_milestone?
      # Usage of `No Milestone` and `none`/`None` in milestone_title to be deprecated
      # https://gitlab.com/gitlab-org/gitlab/-/issues/336044
      params[:milestone_title].to_s.downcase == FILTER_NONE ||
        params[:milestone_title] == Milestone::None.title ||
        params[:milestone_wildcard_id].to_s.downcase == FILTER_NONE
    end

    def filter_by_any_milestone?
      # Usage of `Any Milestone` and `any`/`Any` in milestone_title to be deprecated
      # https://gitlab.com/gitlab-org/gitlab/-/issues/336044
      params[:milestone_title].to_s.downcase == FILTER_ANY ||
        params[:milestone_title] == Milestone::Any.title ||
        params[:milestone_wildcard_id].to_s.downcase == FILTER_ANY
    end

    def filter_by_upcoming_milestone?
      # Usage of `#upcoming` in milestone_title to be deprecated
      # https://gitlab.com/gitlab-org/gitlab/-/issues/336044
      params[:milestone_title] == Milestone::Upcoming.name ||
        params[:milestone_wildcard_id].to_s.downcase == FILTER_UPCOMING
    end

    def filter_by_started_milestone?
      # Usage of `#started` in milestone_title to be deprecated
      # https://gitlab.com/gitlab-org/gitlab/-/issues/336044
      params[:milestone_title] == Milestone::Started.name ||
        params[:milestone_wildcard_id].to_s.downcase == FILTER_STARTED
    end

    def filter_by_no_release?
      params[:release_tag].to_s.downcase == FILTER_NONE
    end

    def filter_by_any_release?
      params[:release_tag].to_s.downcase == FILTER_ANY
    end

    def filter_by_no_reaction?
      params[:my_reaction_emoji].to_s.downcase == FILTER_NONE
    end

    def filter_by_any_reaction?
      params[:my_reaction_emoji].to_s.downcase == FILTER_ANY
    end

    def releases?
      params[:release_tag].present?
    end

    def project?
      project_id.present?
    end

    def group?
      group_id.present?
    end

    def related_groups
      if project? && project&.group && Ability.allowed?(current_user, :read_group, project.group)
        project.group.self_and_ancestors
      elsif group
        [group]
      elsif current_user
        Gitlab::ObjectHierarchy.new(current_user.authorized_groups, current_user.groups).all_objects
      else
        []
      end
    end

    def project
      strong_memoize(:project) do
        next nil unless project?

        project = project_id.is_a?(Project) ? project_id : Project.find(project_id)
        project = nil unless Ability.allowed?(current_user, :"read_#{klass.to_ability_name}", project)

        project
      end
    end

    def group
      strong_memoize(:group) do
        next nil unless group?

        group = group_id.is_a?(Group) ? group_id : Group.find(group_id)
        group = nil unless Ability.allowed?(current_user, :read_group, group)

        group
      end
    end

    def project_id
      params[:project_id]
    end

    def group_id
      params[:group_id]
    end

    def projects
      strong_memoize(:projects) do
        next Array.wrap(project) if project?

        projects_public_or_visible_to_user
          .with_feature_available_for_user(klass.base_class, current_user)
          .without_order
      end
    end

    def milestones
      strong_memoize(:milestones) do
        if milestones?
          if project?
            project_group_id = project.group&.id
            project_id = project.id
          end

          project_group_id = group.id if group

          search_params =
            { title: params[:milestone_title], project_ids: project_id, group_ids: project_group_id }

          MilestonesFinder.new(search_params).execute # rubocop: disable CodeReuse/Finder
        else
          Milestone.none
        end
      end
    end

    def current_user_related?
      scope = params[:scope]
      scope == 'created_by_me' || scope == 'authored' || scope == 'assigned_to_me'
    end

    def find_group_projects
      return Project.none unless group

      if params[:include_subgroups]
        Project.where(namespace_id: group.self_and_descendant_ids) # rubocop: disable CodeReuse/ActiveRecord
      else
        group.projects
      end
    end

    # We use Hash#merge in a few places, so let's support it
    def merge(other)
      self.class.new(params.merge(other), current_user, klass)
    end

    # Just for symmetry, and in case someone tries to use it
    def merge!(other)
      params.merge!(other)
    end

    def parent
      project || group
    end

    def user_can_see_all_issuables?
      Ability.allowed?(current_user, :read_all_resources)
    end
    strong_memoize_attr :user_can_see_all_issuables?

    private

    def projects_public_or_visible_to_user
      projects =
        if group
          if params[:projects]
            find_group_projects.id_in(params[:projects])
          else
            find_group_projects
          end
        elsif params[:projects]
          Project.id_in(params[:projects])
        else
          Project
        end

      projects.public_or_visible_to_user(current_user, min_access_level)
    end

    def min_access_level
      ProjectFeature.required_minimum_access_level(klass.base_class)
    end

    def method_missing(method_name, *args, &block)
      if method_name[-1] == '?'
        params[method_name[0..-2].to_sym].present?
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name[-1] == '?'
    end
  end
end
