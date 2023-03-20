# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class DeploymentCountResolver < BaseResolver
        type Types::Analytics::CycleAnalytics::MetricType, null: true

        argument :from, Types::TimeType,
          required: true,
          description: 'Deployments finished after the date.'

        argument :to, Types::TimeType,
          required: true,
          description: 'Deployments finished before the date.'

        def resolve(**args)
          value = count(args)
          {
            value: value,
            title: n_('Deploy', 'Deploys', value.to_i),
            identifier: 'deploys',
            links: []
          }
        end

        private

        def count(args)
          finder = DeploymentsFinder.new({
            finished_after: args[:from],
            finished_before: args[:to],
            project: object.project,
            status: :success,
            order_by: :finished_at
          })

          finder.execute.count
        end

        # :project level: no customization, returning the original resolver
        # :group level: add the project_ids argument
        def self.[](context = :project)
          case context
          when :project
            self
          when :group
            Class.new(self) do
              argument :project_ids, [GraphQL::Types::ID],
                required: false,
                description: 'Project IDs within the group hierarchy.'
            end

          end
        end
      end
    end
  end
end

mod = Resolvers::Analytics::CycleAnalytics::DeploymentCountResolver
mod.prepend_mod_with('Resolvers::Analytics::CycleAnalytics::DeploymentCountResolver')
