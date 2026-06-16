# frozen_string_literal: true

module Resolvers
  module WorkItems
    # Resolves valid target work item types and a suggested target for moving
    # work items of one or more source types into the namespace this resolver
    # is scoped to.
    #
    # Designed to serve both:
    # - the single move modal (pass one source type id; read the first result), and
    # - the bulk move wizard (pass the unique source type ids in the selection;
    #   render one mapping row per result).
    #
    # The matching algorithm lives in
    # `::WorkItems::Types::MoveTargetsService` and is shared with the move
    # mutation's validation so the dropdown and the action stay consistent.
    class MoveTargetsResolver < BaseResolver
      include ::Gitlab::Utils::StrongMemoize
      include ::Gitlab::Graphql::Authorize::AuthorizeResource

      type [::Types::WorkItems::MoveTargetType], null: true

      authorize :read_namespace

      MAX_SOURCE_TYPES = 50

      argument :source_full_path, GraphQL::Types::String,
        required: true,
        description: 'Full path of the source namespace. For example, `gitlab-org/gitlab-foss`.'

      argument :source_type_ids, [::Types::GlobalIDType[::WorkItems::Type]],
        required: true,
        description: <<~DESC.squish
          Global IDs of the source work item types to compute move targets for.
          A maximum of #{MAX_SOURCE_TYPES} IDs can be provided.
        DESC

      def ready?(**args)
        if args[:source_type_ids].size > MAX_SOURCE_TYPES
          raise Gitlab::Graphql::Errors::ArgumentError,
            format(
              _('No more than %{max_source_types} source work item types can be provided at a time.'),
              max_source_types: MAX_SOURCE_TYPES
            )
        end

        super
      end

      def resolve(source_full_path:, source_type_ids:)
        source_namespace = authorized_find!(full_path: source_full_path)

        ::WorkItems::Types::MoveTargetsService.new(
          current_user: current_user,
          source_namespace: source_namespace,
          target_namespace: object,
          source_type_ids: source_type_ids.map(&:model_id)
        ).execute
      end

      private

      # Override for `authorized_find!`: resolves a full path to a `Namespace`
      # (the default only resolves GIDs).
      def find_object(full_path:)
        ::Gitlab::Graphql::Loaders::FullPathModelLoader.new(::Namespace, full_path).find&.sync
      end
    end
  end
end
