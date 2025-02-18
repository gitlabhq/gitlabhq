# frozen_string_literal: true

class Dashboard::ProjectsController < Dashboard::ApplicationController
  include ParamsBackwardCompatibility
  include RendersMemberAccess
  include RendersProjectsList
  include SortingHelper
  include SortingPreference
  include FiltersEvents

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }
  before_action :set_non_archived_param, only: [:index, :starred]
  before_action :set_sorting
  # When your_work_projects_vue FF is enabled we load the projects via GraphQL query
  # so we don't want to preload the projects at the controller level to avoid duplicate queries.
  before_action :projects, only: [:index], unless: :your_work_projects_vue_feature_flag_enabled?
  skip_cross_project_access_check :index, :starred

  feature_category :groups_and_projects
  urgency :low, [:starred, :index]

  def index
    if your_work_projects_vue_feature_flag_enabled?
      return redirect_to personal_dashboard_projects_path if params[:personal] == "true"
      return redirect_to inactive_dashboard_projects_path if params[:archived] == "only"
    end

    respond_to do |format|
      format.html do
        render_projects
      end
      format.atom do
        load_events
        render layout: 'xml'
      end
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", projects: @projects)
        }
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def starred
    unless your_work_projects_vue_feature_flag_enabled?
      @projects = load_projects(params.merge(starred: true, not_aimed_for_deletion: true))
        .includes(:forked_from_project, :topics)
    end

    @groups = []

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", projects: @projects)
        }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def projects
    @projects ||= load_projects(params.merge(non_public: true, not_aimed_for_deletion: true))
  end

  def render_projects
    # n+1: https://gitlab.com/gitlab-org/gitlab-foss/issues/40260
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      render
    end
  end

  def load_projects(finder_params)
    @all_user_projects = ProjectsFinder.new(
      params: { non_public: true, archived: false,
                not_aimed_for_deletion: true }, current_user: current_user).execute
    @all_starred_projects = ProjectsFinder.new(
      params: { starred: true, archived: false,
                not_aimed_for_deletion: true }, current_user: current_user).execute

    finder_params[:use_cte] = true if use_cte_for_finder?

    projects = ProjectsFinder.new(params: finder_params, current_user: current_user).execute

    projects = preload_associations(projects)
    projects = projects.page(finder_params[:page])

    prepare_projects_for_rendering(projects)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_associations(projects)
    projects.includes(:route, :creator, :group, :topics, namespace: [:route, :owner]).preload(:project_feature)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def use_cte_for_finder?
    # The starred action loads public projects, which causes the CTE to be less efficient
    action_name == 'index'
  end

  def load_events
    projects = ProjectsFinder
                .new(params: params.merge(non_public: true, not_aimed_for_deletion: true), current_user: current_user)
                .execute

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def set_sorting
    params[:sort] = set_sort_order
    @sort = params[:sort]
  end

  def default_sort_order
    sort_value_name
  end

  def sorting_field
    Project::SORTING_PREFERENCE_FIELD
  end

  def your_work_projects_vue_feature_flag_enabled?
    Feature.enabled?(:your_work_projects_vue, current_user)
  end
end

Dashboard::ProjectsController.prepend_mod_with('Dashboard::ProjectsController')
