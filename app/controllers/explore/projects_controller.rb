# frozen_string_literal: true

class Explore::ProjectsController < Explore::ApplicationController
  include ParamsBackwardCompatibility
  include RendersMemberAccess
  include RendersProjectsList
  include SortingHelper
  include SortingPreference

  MIN_SEARCH_LENGTH = 3
  RSS_ENTRIES_LIMIT = 20

  before_action :set_non_archived_param
  before_action :set_sorting
  before_action :show_alert_if_search_is_disabled, only: [:index]

  feature_category :groups_and_projects
  # TODO: Set higher urgency after addressing https://gitlab.com/gitlab-org/gitlab/-/issues/357913
  # and https://gitlab.com/gitlab-org/gitlab/-/issues/358945
  urgency :low, [:index, :topics, :topic]

  def index; end

  def topics
    load_topics
  end

  def topic
    load_topic

    return render_404 unless @topic

    @projects = load_projects

    respond_to do |format|
      format.html
      format.atom do
        @projects = @projects.projects_order_id_desc.limit(RSS_ENTRIES_LIMIT)
        render layout: 'xml'
      end
    end
  end

  private

  def load_projects
    finder_params = {
      minimum_search_length: MIN_SEARCH_LENGTH,
      not_aimed_for_deletion: true,
      current_organization: current_organization,
      sort: @sort
    }
    finder_params[:topic] = @topic.name if @topic

    projects = ProjectsFinder.new(current_user: current_user, params: projects_finder_params.merge(finder_params))
                              .execute

    projects = preload_associations(projects)
    projects = projects.page(pagination_params[:page]).without_count

    prepare_projects_for_rendering(projects)
  end

  # Keys read by ProjectsFinder; permitted here so raw params are not forwarded.
  # :sort and :topic are injected in load_projects.
  def projects_finder_params
    params.permit(
      :archived, :non_archived, :visibility_level, :personal, :starred, :name, :search,
      :topic_id, :namespace_path, :min_access_level, :owned, :tag,
      :include_pending_delete, :id_after, :id_before, :marked_for_deletion_on,
      :aimed_for_deletion, :last_activity_after, :last_activity_before, :repository_storage,
      :language_name, :with_issues_enabled, :with_merge_requests_enabled,
      :active, :last_repository_check_failed, full_paths: []
    )
  end

  def load_topics
    @topics = Projects::TopicsFinder.new(
      params: topics_finder_params,
      organization_id: current_organization&.id
    ).execute.page(pagination_params[:page]).without_count
  end

  def load_topic
    topic_name = if Feature.enabled?(:explore_topics_cleaned_path)
                   URI.decode_www_form_component(topic_params[:topic_name])
                 else
                   topic_params[:topic_name]
                 end

    return unless current_organization

    @topic = Projects::Topic.in_organization(current_organization.id).find_by_name_case_insensitive(topic_name)
  end

  def topic_params
    params.permit(:topic_name)
  end

  def topics_finder_params
    params.permit(:search)
  end

  # Read by show_alert_if_search_is_disabled, which checks both keys.
  def search_params
    params.permit(:name, :search)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_associations(projects)
    projects.includes(:route, :creator, :group, :project_feature, :topics, namespace: [:route, :owner])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def set_sorting
    @sort = set_sort_order
  end

  def default_sort_order
    sort_value_latest_activity
  end

  def sorting_field
    Project::SORTING_PREFERENCE_FIELD
  end

  def show_alert_if_search_is_disabled
    if current_user || (search_params[:name].blank? && search_params[:search].blank?) || !html_request? ||
        Feature.disabled?(:disable_anonymous_project_search, type: :ops)
      return
    end

    flash.now[:notice] = _('You must sign in to search for specific projects.')
  end

  def current_organization
    ::Current.organization
  end
end

Explore::ProjectsController.prepend_mod_with('Explore::ProjectsController')
