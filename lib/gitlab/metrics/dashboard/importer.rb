# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      class Importer
        def initialize(dashboard_path, project)
          @dashboard_path = dashboard_path.to_s
          @project = project
        end

        def execute
          return false unless Dashboard::Validator.validate(dashboard_hash, project: project, dashboard_path: dashboard_path)

          Dashboard::Importers::PrometheusMetrics.new(dashboard_hash, project: project, dashboard_path: dashboard_path).execute
        rescue Gitlab::Config::Loader::FormatError
          false
        end

        def execute!
          Dashboard::Validator.validate!(dashboard_hash, project: project, dashboard_path: dashboard_path)

          Dashboard::Importers::PrometheusMetrics.new(dashboard_hash, project: project, dashboard_path: dashboard_path).execute!
        end

        private

        attr_accessor :dashboard_path, :project

        def dashboard_hash
          @dashboard_hash ||= begin
            raw_dashboard = Dashboard::RepoDashboardFinder.read_dashboard(project, dashboard_path)
            return unless raw_dashboard.present?

            ::Gitlab::Config::Loader::Yaml.new(raw_dashboard).load_raw!
          end
        end
      end
    end
  end
end
