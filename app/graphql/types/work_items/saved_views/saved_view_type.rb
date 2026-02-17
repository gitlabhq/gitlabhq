# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class SavedViewType < BaseObject
        graphql_name 'WorkItemSavedViewType'

        authorize :read_saved_view

        expose_permissions Types::PermissionTypes::WorkItems::SavedView

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
          description: 'Filters associated with the saved view. ' \
            'This field can only be resolved for one saved view in any single request.' do
              extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
            end

        field :filter_warnings,
          [Types::WorkItems::SavedViews::FilterWarningType],
          null: true,
          description: 'Warnings associated with the filter values. ' \
            'This field can only be resolved for one saved view in any single request.' do
              extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
            end

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

        field :subscribed,
          ::GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the current user is subscribed to the saved view.'

        field :work_items,
          ::Types::WorkItemType.connection_type,
          null: true,
          experiment: { milestone: '18.8' },
          resolver: ::Resolvers::WorkItems::SavedViews::WorkItemsResolver,
          description: 'Work items associated with the saved view. ' \
            'This field can only be resolved for one saved view in any single request.' do
              extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
            end

        def filters
          filters_data = validated_result[:filters]

          filters_data.deep_transform_keys { |key| key.to_s.camelize(:lower) }
        end

        def filter_warnings
          validated_result[:warnings]
        end

        def subscribed
          BatchLoader::GraphQL.for(object.id).batch(key: current_user.id) do |saved_view_ids, loader, args|
            batch_load_subscriptions(saved_view_ids, loader, args[:key])
          end
        end

        def sort
          object.sort&.to_sym
        end

        def share_url
          namespace = object.namespace

          if namespace.is_a?(::Group)
            Gitlab::Routing.url_helpers.group_saved_view_url(namespace, object.id)
          else
            project = namespace.project
            Gitlab::Routing.url_helpers.project_saved_view_url(project, object.id)
          end
        end

        private

        def validated_result
          context["saved_view_sanitized_result_#{object.id}"] ||= begin
            result = ::WorkItems::SavedViews::FilterSanitizerService.new(
              filter_data: object.filter_data,
              namespace: object.namespace,
              current_user: current_user
            ).execute

            if result.success?
              result.payload
            else
              { filters: {}, warnings: [{ field: :base, message: result.message }] }
            end
          end
        end

        def batch_load_subscriptions(saved_view_ids, loader, user_id)
          subscriptions = ::WorkItems::SavedViews::UserSavedView
                            .for_user(user_id)
                            .for_saved_view(saved_view_ids)
                            .pluck(:saved_view_id) # rubocop: disable CodeReuse/ActiveRecord -- Batch loading requires pluck for performance
                            .to_set

          saved_view_ids.each do |saved_view_id|
            loader.call(saved_view_id, subscriptions.include?(saved_view_id))
          end
        end
      end
    end
  end
end
