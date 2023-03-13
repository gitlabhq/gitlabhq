# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module FlowMetrics
        def self.[](context = :project)
          Class.new(BaseObject) do
            graphql_name "#{context.capitalize}ValueStreamAnalyticsFlowMetrics"
            description 'Exposes aggregated value stream flow metrics'

            field :issue_count,
              Types::Analytics::CycleAnalytics::MetricType,
              null: true,
              description: 'Number of issues opened in the given period.',
              resolver: Resolvers::Analytics::CycleAnalytics::IssueCountResolver[context]
            field :deployment_count,
              Types::Analytics::CycleAnalytics::MetricType,
              null: true,
              description: 'Number of production deployments in the given period.',
              resolver: Resolvers::Analytics::CycleAnalytics::DeploymentCountResolver[context]
          end
        end
      end
    end
  end
end

mod = Types::Analytics::CycleAnalytics::FlowMetrics
mod.prepend_mod_with('Types::Analytics::CycleAnalytics::FlowMetrics')
