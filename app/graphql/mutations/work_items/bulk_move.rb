# frozen_string_literal: true

module Mutations
  module WorkItems
    class BulkMove < BaseMutation
      graphql_name 'WorkItemBulkMove'

      include ::Gitlab::Utils::StrongMemoize
      include ResolvesProject

      MAX_WORK_ITEMS = 100

      description 'Allows move several work items.'

      argument :ids,
        [::Types::GlobalIDType[::WorkItem]],
        required: true,
        description: <<~DESC.squish
          Global ID array of the work items that will be moved.
          IDs that the user can\'t move will be ignored. A max of #{MAX_WORK_ITEMS} can be provided.
        DESC

      argument :source_full_path,
        GraphQL::Types::String,
        required: true,
        description: 'Full path of the source namespace. For example, `gitlab-org/gitlab-foss`.'

      argument :target_full_path,
        GraphQL::Types::String,
        required: true,
        description: 'Full path of the target namespace. For example, `gitlab-org/gitlab-foss`. ' \
          'Only project namespaces are supported.'

      field :moved_work_item_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of work items that were successfully moved.'

      def ready?(**args)
        if args[:ids].size > MAX_WORK_ITEMS
          raise Gitlab::Graphql::Errors::ArgumentError,
            format(
              _('No more than %{max_work_items} work items can be moved at the same time'),
              max_work_items: MAX_WORK_ITEMS
            )
        end

        super
      end

      def resolve(ids:, source_full_path:, target_full_path:)
        target_project = resolve_project(full_path: target_full_path).sync

        if target_project.blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
            _('At this moment, it is only possible to move work items to projects.')
        end

        result = ::WorkItems::BulkMoveService.new(
          current_user: current_user,
          work_item_ids: ids.map(&:model_id),
          source_namespace: namespace_for(source_full_path),
          target_namespace: target_project.project_namespace
        ).execute

        if result.success?
          { moved_work_item_count: result[:moved_work_item_count], errors: result.errors }
        else
          { errors: result.errors }
        end
      end

      private

      def namespace_for(full_path)
        ::Gitlab::Graphql::Loaders::FullPathModelLoader.new(::Namespace, full_path).find&.sync
      end
    end
  end
end
