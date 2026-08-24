# frozen_string_literal: true

class Dashboard::ProjectsController < Dashboard::ApplicationController
  include ParamsBackwardCompatibility
  include RendersMemberAccess
  include RendersProjectsList
  include SortingHelper
  include SortingPreference
  include FiltersEvents

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss, permission: :read_project) }
  before_action :set_non_archived_param, only: [:index]
  before_action :set_sorting
  skip_cross_project_access_check :index

  feature_category :groups_and_projects
  urgency :low, [:index]

  def index
    return redirect_to personal_dashboard_projects_path if projects_finder_params[:personal] == "true"
    return redirect_to inactive_dashboard_projects_path if projects_finder_params[:archived] == "only"

    respond_to do |format|
      format.html do
        render 'dashboard/projects/index'
      end
      format.atom do
        load_events
        render layout: 'xml'
      end
    end
  end

  private

  def load_events
    finder_params = projects_finder_params.merge(non_public: true, not_aimed_for_deletion: true, sort: @sort)
    projects = ProjectsFinder
                .new(params: finder_params, current_user: current_user)
                .execute

    @events = EventCollection
      .new(projects, offset: event_params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def event_params
    params.permit(:offset)
  end

  # Keys read by ProjectsFinder; permitted here so raw params are not forwarded.
  def projects_finder_params
    params.permit(
      # note: :sort is resolved via set_sort_order and injected in load_events
      :archived, :non_archived, :visibility_level, :personal, :starred, :name, :search,
      :tag, :topic, :topic_id, :namespace_path, :min_access_level, :owned,
      :include_pending_delete, :id_after, :id_before, :marked_for_deletion_on,
      :aimed_for_deletion, :last_activity_after, :last_activity_before, :repository_storage,
      :language_name, :with_issues_enabled, :with_merge_requests_enabled,
      :active, :last_repository_check_failed, full_paths: []
    )
  end

  def default_sort_order
    sort_value_name
  end

  def sorting_field
    Project::SORTING_PREFERENCE_FIELD
  end

  def set_sorting
    @sort = set_sort_order
  end
end

Dashboard::ProjectsController.prepend_mod_with('Dashboard::ProjectsController')
