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
          if Feature.enabled?(:query_deploymenys_via_finished_at_in_vsa)
            DeploymentsFinder
              .new(project: @project, finished_after: @from, finished_before: @to, status: :success)
              .execute
              .count
          else
            query = @project.deployments.success.where("created_at >= ?", @from)
            query = query.where("created_at <= ?", @to) if @to
            query.count
          end
        end
      end
    end
  end
end
