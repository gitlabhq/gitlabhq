# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType (inherited from Resolvers::Analytics::CycleAnalytics::BaseCountResolver)
module Resolvers
  module Analytics
    module CycleAnalytics
      class DeploymentCountResolver < BaseCountResolver
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
# rubocop:enable Graphql/ResolverType

mod = Resolvers::Analytics::CycleAnalytics::DeploymentCountResolver
mod.prepend_mod_with('Resolvers::Analytics::CycleAnalytics::DeploymentCountResolver')
