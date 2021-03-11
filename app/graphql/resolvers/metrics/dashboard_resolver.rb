# frozen_string_literal: true

module Resolvers
  module Metrics
    class DashboardResolver < Resolvers::BaseResolver
      type Types::Metrics::DashboardType, null: true
      calls_gitaly!

      argument :path, GraphQL::STRING_TYPE,
               required: true,
               description: "Path to a file which defines metrics dashboard " \
                            "eg: 'config/prometheus/common_metrics.yml'."

      alias_method :environment, :object

      def resolve(**args)
        return unless environment

        ::PerformanceMonitoring::PrometheusDashboard.find_for(**args, **service_params)
      end

      private

      def service_params
        {
          project: environment.project,
          user: current_user,
          options: { environment: environment }
        }
      end
    end
  end
end
