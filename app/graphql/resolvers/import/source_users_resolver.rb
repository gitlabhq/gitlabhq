# frozen_string_literal: true

module Resolvers
  module Import
    class SourceUsersResolver < BaseResolver
      include ::LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :admin_namespace

      type Types::Import::SourceUserType.connection_type, null: true

      alias_method :namespace, :object

      def resolve_with_lookahead(**args)
        return [] if Feature.disabled?(:bulk_import_user_mapping, current_user)

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
