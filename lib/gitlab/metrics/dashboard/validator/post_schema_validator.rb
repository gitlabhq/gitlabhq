# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        class PostSchemaValidator
          def initialize(project: nil, metric_ids: [])
            @project = project
            @metric_ids = metric_ids
          end

          def validate
            [uniq_metric_ids_across_project].compact
          end

          private

          attr_reader :project, :metric_ids

          def uniq_metric_ids_across_project
            # TODO: modify this method to check metric identifier uniqueness across project once we start
            # recording dashboard_path https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38237

            Validator::Errors::DuplicateMetricIds.new if metric_ids.uniq!
          end
        end
      end
    end
  end
end
