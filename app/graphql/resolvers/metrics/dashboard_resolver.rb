# frozen_string_literal: true

module Resolvers
  module Metrics
    class DashboardResolver < Resolvers::BaseResolver
      type Types::Metrics::DashboardType, null: true
      calls_gitaly!

      argument :path, GraphQL::Types::String,
               required: true,
               description: <<~MD
                 Path to a file which defines a metrics dashboard eg: `"config/prometheus/common_metrics.yml"`.
               MD

      alias_method :environment, :object

      def resolve(path:)
        return unless environment

        ::PerformanceMonitoring::PrometheusDashboard.find_for(path: path, **service_params)
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
