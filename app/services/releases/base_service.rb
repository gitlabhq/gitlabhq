# frozen_string_literal: true

module Releases
  class BaseService
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize

    ReleaseProtectedTagAccessError = Class.new(StandardError)

    attr_accessor :project, :current_user, :params

    def initialize(project, user = nil, params = {})
      @project = project
      @current_user = user
      @params = params.dup
    end

    def tag_name
      params[:tag]
    end

    def tag_message
      params[:tag_message]
    end

    def ref
      params[:ref]
    end

    def name
      params[:name] || tag_name
    end

    def description
      params[:description]
    end

    def released_at
      params[:released_at]
    end

    def release
      strong_memoize(:release) do
        project.releases.find_by_tag(tag_name)
      end
    end

    def repository
      strong_memoize(:repository) do
        project.repository
      end
    end

    def existing_tag
      strong_memoize(:existing_tag) do
        repository.find_tag(tag_name)
      end
    end

    def milestones
      return [] unless param_for_milestones_exists?

      strong_memoize(:milestones) do
        MilestonesFinder.new(
          project: project,
          current_user: current_user,
          project_ids: Array(project.id),
          group_ids: Array(project_group_id),
          state: 'all',
          title: params[:milestones],
          ids: params[:milestone_ids]
        ).execute
      end
    end

    def inexistent_milestone_titles
      return [] unless param_for_milestone_titles_provided?

      existing_milestone_titles = milestones.map(&:title)

      Array(params[:milestones]) - existing_milestone_titles
    end

    def inexistent_milestone_ids
      return [] unless param_for_milestone_ids_provided?

      existing_milestone_ids = milestones.map(&:id)

      Array(params[:milestone_ids]) - existing_milestone_ids
    end

    def param_for_milestone_titles_provided?
      !!params[:milestones]
    end

    def param_for_milestone_ids_provided?
      !!params[:milestone_ids]
    end

    def param_for_milestones_provided?
      param_for_milestone_titles_provided? || param_for_milestone_ids_provided?
    end

    def param_for_milestones_exists?
      params[:milestones].present? || params[:milestone_ids].present?
    end

    def execute_hooks(release, action = 'create')
      release.execute_hooks(action)
    end

    # overridden in EE
    def project_group_id; end

    def audit(release, action:)
      # overridden in EE
    end
  end
end

Releases::BaseService.prepend_mod_with('Releases::BaseService')
