# frozen_string_literal: true

module Resolvers
  module Import
    class SourceUsersResolver < BaseResolver
      include ::LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :admin_namespace

      type Types::Import::SourceUserType.connection_type, null: true

      argument :statuses, [::Types::Import::SourceUserStatusEnum],
        required: false,
        description: 'Filter mapping of users on source instance to users on destination instance by status.'

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Query to search mappings by name or username of users on source instance.'

      argument :sort, Types::Import::SourceUserSortEnum,
        description: 'Sort mapping of users on source instance to users on destination instance by the criteria.',
        required: false,
        default_value: :source_name_asc

      alias_method :namespace, :object

      def resolve_with_lookahead(**args)
        return [] if Feature.disabled?(:importer_user_mapping, current_user)

        apply_lookahead(::Import::SourceUsersFinder.new(namespace, context[:current_user], args).execute)
      end

      private

      def preloads
        {
          reassign_to_user: [:reassign_to_user],
          placeholder_user: [:placeholder_user],
          reassigned_by_user: [:reassigned_by_user]
        }
      end
    end
  end
end
