# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Create < BaseMutation
        graphql_name 'WorkItemSavedViewCreate'

        include Mutations::SpamProtection
        include FindsNamespace

        authorize :create_saved_view

        description "Creates a saved view."

        argument :namespace_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Full path of the namespace to create the saved view in.'

        argument :name,
          GraphQL::Types::String,
          required: true,
          description: 'Name of the saved view.'

        argument :description,
          GraphQL::Types::String,
          required: false,
          description: 'Description of the saved view.'

        argument :filters,
          ::Types::WorkItems::SavedViews::FilterInputType,
          required: true,
          description: 'Filters associated with the saved view.'

        # rubocop:disable Graphql/JSONType -- Matching the input type in the user preferences update mutation
        argument :display_settings,
          GraphQL::Types::JSON,
          required: true,
          description: 'Display settings associated with the saved view.'
        # rubocop:enable Graphql/JSONType

        argument :sort,
          ::Types::WorkItems::SortEnum,
          required: true,
          description: 'Sort option associated with the saved view.'

        # TODO: Remove once frontend has migrated to use is_private
        argument :private,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Whether the saved view is private. Default is true.',
          deprecated: {
            reason: 'Replaced by `isPrivate` argument',
            milestone: '18.10'
          }

        argument :is_private,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Whether the saved view is private. Default is true.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Created saved view.'

        field :errors, [GraphQL::Types::String],
          null: false,
          scopes: [:api],
          description: 'Errors encountered during the mutation.'

        validates mutually_exclusive: [:private, :is_private]

        def resolve(namespace_path:, **attrs)
          container = authorized_find!(namespace_path)

          if attrs.key?(:is_private)
            attrs[:private] = attrs.delete(:is_private)
          elsif !attrs.key?(:private)
            attrs[:private] = true
          end

          result = ::WorkItems::SavedViews::CreateService.new(
            current_user: current_user,
            container: container,
            params: attrs
          ).execute

          if result.success?
            check_spam_action_response!(result.payload[:saved_view])
            { saved_view: result.payload[:saved_view], errors: [] }
          else
            { saved_view: nil, errors: result.errors }
          end
        end
      end
    end
  end
end
