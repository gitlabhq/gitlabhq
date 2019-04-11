# frozen_string_literal: true

# Searches a projects repository for a metrics dashboard and formats the output.
# Expects any custom dashboards will be located in `.gitlab/dashboards`
class MetricsDashboardService
  DASHBOARD_ROOT = ".gitlab/dashboards"
  DASHBOARD_EXTENSION = '.yml'

  SYSTEM_DASHBOARD_NAME = 'system_dashboard'
  SYSTEM_DASHBOARD_ROOT = "config/prometheus"
  SYSTEM_DASHBOARD_PATH = Rails.root.join(SYSTEM_DASHBOARD_ROOT, "#{SYSTEM_DASHBOARD_NAME}#{DASHBOARD_EXTENSION}")

  def initialize(project)
    @project = project
  end

  # Returns a DB-supplemented json representation of a dashboard config file.
  #
  # param: dashboard_name [String] Filename of dashboard w/o an extension.
  #     If not provided, the system dashboard will be returned.
  def find(dashboard_name = nil)
    unless Feature.enabled?(:environment_metrics_show_multiple_dashboards, @project)
      return process_dashboard(system_dashboard)
    end

    dashboard = Rails.cache.fetch(cache_key(dashboard_name)) do
      dashboard_name ? project_dashboard(dashboard) : system_dashboard
    end

    process_dashboard(dashboard)
  end

  private

  # Returns the base metrics shipped with every GitLab service.
  def system_dashboard
    YAML.load_file(SYSTEM_DASHBOARD_PATH)
  end

  # Searches the project repo for a custom-defined dashboard.
  def project_dashboard(dashboard_name)
    Gitlab::Template::Finders::RepoTemplateFinder.new(
      project,
      DASHBOARD_ROOT,
      DASHBOARD_EXTENSION
    ).find(dashboard_name).read
  end

  def cache_key(dashboard_name)
    return "metrics_dashboard_#{SYSTEM_DASHBOARD_NAME}" unless dashboard_name

    "project_#{@project.id}_metrics_dashboard_#{dashboard_name}"
  end

  # TODO: "Processing" the dashboard needs to include several steps such as
  # inserting metric ids and alert information.
  def process_dashboard(dashboard)
    dashboard.to_json
  end
end
