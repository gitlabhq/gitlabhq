# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Deploy < Base
        def identifier
          :deploys
        end

        def title
          n_('Deploy', 'Deploys', value.to_i)
        end

        def value
          @value ||= Value::PrettyNumeric.new(deployments_count)
        end

        private

        def deployments_count
          DeploymentsFinder
            .new(project: @project, finished_after: @options[:from], finished_before: @options[:to], status: :success, order_by: :finished_at)
            .execute
            .count
        end
      end
    end
  end
end

Gitlab::CycleAnalytics::Summary::Deploy.prepend_mod_with('Gitlab::CycleAnalytics::Summary::Deploy')
