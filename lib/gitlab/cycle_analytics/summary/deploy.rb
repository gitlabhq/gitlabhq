# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Deploy < Base
        def title
          n_('Deploy', 'Deploys', value.to_i)
        end

        def value
          @value ||= Value::PrettyNumeric.new(deployments_count)
        end

        private

        def deployments_count
          DeploymentsFinder
            .new(project: @project, finished_after: @from, finished_before: @to, status: :success, order_by: :finished_at)
            .execute
            .count
        end
      end
    end
  end
end
