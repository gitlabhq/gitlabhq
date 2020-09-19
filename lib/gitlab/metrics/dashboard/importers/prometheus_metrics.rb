# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Importers
        class PrometheusMetrics
          ALLOWED_ATTRIBUTES = %i(title query y_label unit legend group dashboard_path).freeze

          # Takes a JSON schema validated dashboard hash and
          # imports metrics to database
          def initialize(dashboard_hash, project:, dashboard_path:)
            @dashboard_hash = dashboard_hash
            @project = project
            @dashboard_path = dashboard_path
          end

          def execute
            import
          rescue ActiveRecord::RecordInvalid, ::Gitlab::Metrics::Dashboard::Transformers::TransformerError
            false
          end

          def execute!
            import
          end

          private

          attr_reader :dashboard_hash, :project, :dashboard_path

          def import
            delete_stale_metrics
            create_or_update_metrics
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def create_or_update_metrics
            # TODO: use upsert and worker for callbacks?
            prometheus_metrics_attributes.each do |attributes|
              prometheus_metric = PrometheusMetric.find_or_initialize_by(attributes.slice(:identifier, :project))
              prometheus_metric.update!(attributes.slice(*ALLOWED_ATTRIBUTES))
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def delete_stale_metrics
            identifiers = prometheus_metrics_attributes.map { |metric_attributes| metric_attributes[:identifier] }

            stale_metrics = PrometheusMetric.for_project(project)
              .for_dashboard_path(dashboard_path)
              .for_group(Enums::PrometheusMetric.groups[:custom])
              .not_identifier(identifiers)

            # TODO: use destroy_all and worker for callbacks?
            stale_metrics.each(&:destroy)
          end

          def prometheus_metrics_attributes
            @prometheus_metrics_attributes ||= begin
              Dashboard::Transformers::Yml::V1::PrometheusMetrics.new(
                dashboard_hash,
                project: project,
                dashboard_path: dashboard_path
              ).execute
            end
          end
        end
      end
    end
  end
end
