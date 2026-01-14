# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Reorder < BaseMutation
        graphql_name 'WorkItemSavedViewReorder'

        authorize :read_saved_view

        description "Reorders a saved view for the current user."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view to be reordered.'

        argument :move_before_id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: false,
          description: 'Global ID of a saved view that the reordered view should be placed before.',
          prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id).model_id.to_i }

        argument :move_after_id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: false,
          description: 'Global ID of a saved view that the reordered view should be placed after.',
          prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id).model_id.to_i }

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Reordered saved view.'

        field :errors,
          [GraphQL::Types::String],
          null: false,
          scopes: [:api],
          description: 'Errors encountered during the mutation.'

        validates exactly_one_of: [:move_before_id, :move_after_id]

        def resolve(id:, **args)
          saved_view = authorized_find!(id: id)

          return feature_disabled_error unless saved_views_enabled?(saved_view)

          result = ::WorkItems::SavedViews::ReorderService.new(
            current_user: current_user,
            params: args.slice(:move_before_id, :move_after_id)
          ).execute(saved_view)

          if result.success?
            { saved_view: saved_view, errors: [] }
          else
            { saved_view: nil, errors: [result.message] }
          end
        end

        private

        def saved_views_enabled?(saved_view)
          saved_view.namespace.owner_entity.work_items_saved_views_enabled?(current_user)
        end

        def feature_disabled_error
          { saved_view: nil, errors: ['Saved views are not enabled for this namespace.'] }
        end
      end
    end
  end
end
