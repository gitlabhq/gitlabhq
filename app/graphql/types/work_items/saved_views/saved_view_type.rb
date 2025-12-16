# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class SavedViewType < BaseObject
        graphql_name 'WorkItemSavedViewType'

        authorize :read_saved_view

        field :id,
          Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          null: false,
          description: 'ID of the saved view.'

        field :namespace_id,
          Types::GlobalIDType[Namespace],
          null: false,
          description: 'ID of the namespace of the saved view.'

        field :name,
          ::GraphQL::Types::String,
          null: false,
          description: 'Name of the saved view.'

        field :description,
          ::GraphQL::Types::String,
          null: true,
          description: 'Description of the saved view.'

        field :filters,
          ::GraphQL::Types::JSON,
          null: true,
          description: 'Filters associated with the saved view.'

        field :filter_warnings,
          [Types::WorkItems::SavedViews::FilterWarningType],
          null: true,
          description: 'Warnings associated with the filter values.'

        field :display_settings,
          ::GraphQL::Types::JSON,
          null: true,
          description: 'Display settings associated with the saved view.'

        field :sort,
          Types::WorkItems::SortEnum,
          null: true,
          description: 'Sort option associated with the saved view.'

        field :private,
          ::GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the saved view is private.'

        field :share_url,
          ::GraphQL::Types::String,
          null: false,
          description: 'URL to auto subscribe users to the view.'

        field :work_items,
          ::Types::WorkItemType.connection_type,
          null: true,
          experiment: { milestone: '18.7' },
          description: 'Work items associated with the saved view.'

        def filters
          {}
        end

        def filter_warnings
          []
        end

        def share_url
          namespace = object.namespace

          if namespace.is_a?(::Group)
            Gitlab::Routing.url_helpers.subscribe_group_saved_view_url(namespace, object.id)
          else
            project = namespace.project
            Gitlab::Routing.url_helpers.subscribe_project_saved_view_url(project, object.id)
          end
        end
      end
    end
  end
end
