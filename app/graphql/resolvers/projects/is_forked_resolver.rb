# frozen_string_literal: true

module Resolvers
  module Projects
    class IsForkedResolver < BaseResolver
      type GraphQL::Types::Boolean, null: false

      def resolve
        lazy_fork_network_members = BatchLoader::GraphQL.for(object.id).batch do |ids, loader|
          ForkNetworkMember.by_projects(ids)
            .with_fork_network
            .find_each do |fork_network_member|
              loader.call(fork_network_member.project_id, fork_network_member)
            end
        end

        Gitlab::Graphql::Lazy.with_value(lazy_fork_network_members) do |fork_network_member|
          next false if fork_network_member.nil?

          fork_network_member.fork_network.root_project_id != object.id
        end
      end
    end
  end
end
