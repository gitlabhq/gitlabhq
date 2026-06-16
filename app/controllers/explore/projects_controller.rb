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

    params[:topic] = @topic.name
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
      current_organization: current_organization
    }

    projects = ProjectsFinder.new(current_user: current_user, params: params.merge(finder_params)).execute

    projects = preload_associations(projects)
    projects = projects.page(pagination_params[:page]).without_count

    prepare_projects_for_rendering(projects)
  end

  def load_topics
    @topics = Projects::TopicsFinder.new(
      params: params.permit(:search),
      organization_id: current_organization&.id
    ).execute.page(pagination_params[:page]).without_count
  end

  def load_topic
    topic_name = if Feature.enabled?(:explore_topics_cleaned_path)
                   URI.decode_www_form_component(params[:topic_name])
                 else
                   params[:topic_name]
                 end

    return unless current_organization

    @topic = Projects::Topic.in_organization(current_organization.id).find_by_name_case_insensitive(topic_name)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_associations(projects)
    projects.includes(:route, :creator, :group, :project_feature, :topics, namespace: [:route, :owner])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def set_sorting
    params[:sort] = set_sort_order
    @sort = params[:sort]
  end

  def default_sort_order
    sort_value_latest_activity
  end

  def sorting_field
    Project::SORTING_PREFERENCE_FIELD
  end

  def show_alert_if_search_is_disabled
    if current_user || (params[:name].blank? && params[:search].blank?) || !html_request? || Feature.disabled?(
      :disable_anonymous_project_search, type: :ops)
      return
    end

    flash.now[:notice] = _('You must sign in to search for specific projects.')
  end

  def current_organization
    ::Current.organization
  end
end

Explore::ProjectsController.prepend_mod_with('Explore::ProjectsController')
