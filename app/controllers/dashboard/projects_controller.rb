# frozen_string_literal: true

class Dashboard::ProjectsController < Dashboard::ApplicationController
  include ParamsBackwardCompatibility
  include RendersMemberAccess
  include RendersProjectsList
  include SortingHelper
  include SortingPreference
  include FiltersEvents

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }
  before_action :set_non_archived_param, only: [:index]
  before_action :set_sorting
  skip_cross_project_access_check :index

  feature_category :groups_and_projects
  urgency :low, [:index]

  def index
    return redirect_to personal_dashboard_projects_path if params[:personal] == "true"
    return redirect_to inactive_dashboard_projects_path if params[:archived] == "only"

    respond_to do |format|
      format.html do
        render
      end
      format.atom do
        load_events
        render layout: 'xml'
      end
    end
  end

  private

  def load_events
    projects = ProjectsFinder
                .new(params: params.merge(non_public: true, not_aimed_for_deletion: true), current_user: current_user)
                .execute

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def default_sort_order
    sort_value_name
  end

  def sorting_field
    Project::SORTING_PREFERENCE_FIELD
  end

  def set_sorting
    params[:sort] = set_sort_order
    @sort = params[:sort]
  end
end

Dashboard::ProjectsController.prepend_mod_with('Dashboard::ProjectsController')
