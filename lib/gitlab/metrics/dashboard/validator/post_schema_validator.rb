# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        class PostSchemaValidator
          def initialize(metric_ids:, project: nil, dashboard_path: nil)
            @metric_ids = metric_ids
            @project = project
            @dashboard_path = dashboard_path
          end

          def validate
            errors = []
            errors << uniq_metric_ids
            errors.compact
          end

          private

          attr_reader :project, :metric_ids, :dashboard_path

          def uniq_metric_ids
            return Validator::Errors::DuplicateMetricIds.new if metric_ids.uniq!

            uniq_metric_ids_across_project if project.present? || dashboard_path.present?
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def uniq_metric_ids_across_project
            return ArgumentError.new(_('Both project and dashboard_path are required')) unless
              dashboard_path.present? && project.present?

            # If PrometheusMetric identifier is not unique across project and dashboard_path,
            # we need to error because we don't know if the user is trying to create a new metric
            # or update an existing one.
            identifier_on_other_dashboard = PrometheusMetric.where(
              project: project,
              identifier: metric_ids
            ).where.not(
              dashboard_path: dashboard_path
            ).exists?

            Validator::Errors::DuplicateMetricIds.new if identifier_on_other_dashboard
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
