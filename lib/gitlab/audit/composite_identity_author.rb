# frozen_string_literal: true

module Gitlab
  module Audit
    # Wraps the service account that authenticated via a composite identity
    # (OAuth on behalf of a human) so that audit events stay attributed to the
    # service account as the primary actor: #id delegates to the SA, keeping
    # author_id correct and queryable, while #name surfaces the authorizing
    # human for human-readable display.
    #
    # The structured human linkage is recorded separately as flat
    # human_-prefixed keys in the audit event details; see
    # Gitlab::Audit::Auditor.
    class CompositeIdentityAuthor < SimpleDelegator
      AUTHOR_NAME_MAX_LENGTH = 255
      ON_BEHALF_OF = " on behalf of "
      MAX_NAME_LENGTH = (AUTHOR_NAME_MAX_LENGTH - ON_BEHALF_OF.length) / 2

      # @param [User] service_account the authenticating actor (primary user)
      # @param [User] human_author the authorizing principal (scoped user)
      def initialize(service_account, human_author:)
        @human_author = human_author

        super(service_account)
      end

      def name
        "#{truncated_name}#{ON_BEHALF_OF}#{truncated_human_name}"
      end

      private

      def truncated_name
        __getobj__.name.to_s.truncate(MAX_NAME_LENGTH)
      end

      def truncated_human_name
        @human_author.to_reference.to_s.truncate(MAX_NAME_LENGTH)
      end
    end
  end
end
