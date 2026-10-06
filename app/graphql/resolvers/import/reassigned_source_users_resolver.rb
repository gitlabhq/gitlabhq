# frozen_string_literal: true

module Resolvers
  module Import
    class ReassignedSourceUsersResolver < BaseResolver
      include ::LooksAhead

      type Types::Import::SourceUserType.connection_type, null: true

      alias_method :user, :object

      def resolve_with_lookahead(**)
        return ::Import::SourceUser.none if Feature.disabled?(:revoke_import_source_user_reassignment, current_user)

        apply_lookahead(
          ::Import::SourceUser
            .for_reassign_to_user(user)
            .by_statuses(::Import::SourceUser::STATUSES[:completed])
        )
      end

      private

      def preloads
        {
          reassign_to_user: [:reassign_to_user],
          placeholder_user: [:placeholder_user],
          reassigned_by_user: [:reassigned_by_user],
          namespace: [:namespace]
        }
      end
    end
  end
end
