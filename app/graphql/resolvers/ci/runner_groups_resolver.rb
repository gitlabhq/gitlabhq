# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerGroupsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ResolvesGroups

      type Types::GroupType.connection_type, null: true

      authorize :read_runner
      authorizes_object!

      alias_method :runner, :object

      def resolve_with_lookahead(**args)
        return unless runner.group_type?

        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_namespaces) do |runner_ids, loader|
          plucked_runner_and_namespace_ids =
            ::Ci::RunnerNamespace
              .for_runner(runner_ids)
              .select(:runner_id, :namespace_id)
              .pluck(:runner_id, :namespace_id) # rubocop: disable CodeReuse/ActiveRecord)

          namespace_ids = plucked_runner_and_namespace_ids.collect(&:last).uniq
          groups = apply_lookahead(::Group.id_in(namespace_ids))
          Preloaders::GroupPolicyPreloader.new(groups, current_user).execute
          groups_by_id = groups.index_by(&:id)

          runner_group_ids_by_runner_id =
            plucked_runner_and_namespace_ids
              .group_by { |runner_id, _namespace_id| runner_id }
              .transform_values { |values| values.filter_map { |_runner_id, namespace_id| groups_by_id[namespace_id] } }

          runner_ids.each do |runner_id|
            runner_namespaces = runner_group_ids_by_runner_id[runner_id] || []

            loader.call(runner_id, runner_namespaces)
          end
        end
      end
    end
  end
end
