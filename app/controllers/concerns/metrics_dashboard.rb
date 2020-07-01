# frozen_string_literal: true

# Provides an action which fetches a metrics dashboard according
# to the parameters specified by the controller.
module MetricsDashboard
  include RenderServiceResults
  include ChecksCollaboration
  include EnvironmentsHelper

  extend ActiveSupport::Concern

  def metrics_dashboard
    result = dashboard_finder.find(
      project_for_dashboard,
      current_user,
      metrics_dashboard_params.to_h.symbolize_keys
    )

    if result
      result[:all_dashboards] = all_dashboards if include_all_dashboards?
      result[:metrics_data] = metrics_data(project_for_dashboard, environment_for_dashboard)
    end

    respond_to do |format|
      if result.nil?
        format.json { continue_polling_response }
      elsif result[:status] == :success
        format.json { render dashboard_success_response(result) }
      else
        format.json { render dashboard_error_response(result) }
      end
    end
  end

  private

  def all_dashboards
    dashboard_finder
      .find_all_paths(project_for_dashboard)
      .map(&method(:amend_dashboard))
  end

  def amend_dashboard(dashboard)
    project_dashboard = project_for_dashboard && !dashboard[:out_of_the_box_dashboard]

    dashboard[:can_edit] = project_dashboard ? can_edit?(dashboard) : false
    dashboard[:project_blob_path] = project_dashboard ? dashboard_project_blob_path(dashboard) : nil
    dashboard[:starred] = starred_dashboards.include?(dashboard[:path])
    dashboard[:user_starred_path] = project_for_dashboard ? user_starred_path(project_for_dashboard, dashboard[:path]) : nil

    dashboard
  end

  def user_starred_path(project, path)
    expose_path(api_v4_projects_metrics_user_starred_dashboards_path(id: project.id, params: { dashboard_path: path }))
  end

  def dashboard_project_blob_path(dashboard)
    project_blob_path(project_for_dashboard, File.join(project_for_dashboard.default_branch, dashboard.fetch(:path, "")))
  end

  def can_edit?(dashboard)
    can_collaborate_with_project?(project_for_dashboard, ref: project_for_dashboard.default_branch)
  end

  # Override in class to provide arguments to the finder.
  def metrics_dashboard_params
    {}
  end

  # Override in class if response requires complete list of
  # dashboards in addition to requested dashboard body.
  def include_all_dashboards?
    false
  end

  def dashboard_finder
    ::Gitlab::Metrics::Dashboard::Finder
  end

  def starred_dashboards
    @starred_dashboards ||= begin
      if project_for_dashboard.present?
        ::Metrics::UsersStarredDashboardsFinder
          .new(user: current_user, project: project_for_dashboard)
          .execute
          .map(&:dashboard_path)
          .to_set
      else
        Set.new
      end
    end
  end

  # Project is not defined for group and admin level clusters.
  def project_for_dashboard
    defined?(project) ? project : nil
  end

  def environment_for_dashboard
    defined?(environment) ? environment : nil
  end

  def dashboard_success_response(result)
    {
      status: :ok,
      json: result.slice(:all_dashboards, :dashboard, :status, :metrics_data)
    }
  end

  def dashboard_error_response(result)
    {
      status: result[:http_status] || :bad_request,
      json: result.slice(:all_dashboards, :message, :status)
    }
  end
end
