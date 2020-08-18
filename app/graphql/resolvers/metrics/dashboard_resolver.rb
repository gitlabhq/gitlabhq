# frozen_string_literal: true

module Resolvers
  module Metrics
    class DashboardResolver < Resolvers::BaseResolver
      argument :path, GraphQL::STRING_TYPE,
               required: true,
               description: "Path to a file which defines metrics dashboard eg: 'config/prometheus/common_metrics.yml'"

      type Types::Metrics::DashboardType, null: true

      alias_method :environment, :object

      def resolve(**args)
        return unless environment

        ::PerformanceMonitoring::PrometheusDashboard
          .find_for(project: environment.project, user: context[:current_user], path: args[:path], options: { environment: environment })
      end
    end
  end
end
