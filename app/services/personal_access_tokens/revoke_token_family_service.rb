# frozen_string_literal: true

module PersonalAccessTokens
  class RevokeTokenFamilyService
    def initialize(token)
      @token = token
    end

    def execute
      # Despite using #update_all, there should only be a single active token.
      # A token family is a chain of rotated tokens. Once rotated, the
      # previous token is revoked.
      pat_family.active.update_all(revoked: true)

      ServiceResponse.success
    end

    private

    attr_reader :token

    def pat_family
      # rubocop: disable CodeReuse/ActiveRecord
      cte = Gitlab::SQL::RecursiveCTE.new(:personal_access_tokens_cte)
      personal_access_token_table = Arel::Table.new(:personal_access_tokens)

      cte << PersonalAccessToken
               .where(personal_access_token_table[:previous_personal_access_token_id].eq(token.id))
      cte << PersonalAccessToken
               .from([personal_access_token_table, cte.table])
               .where(personal_access_token_table[:previous_personal_access_token_id].eq(cte.table[:id]))
      PersonalAccessToken.with.recursive(cte.to_arel).from(cte.alias_to(personal_access_token_table))
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
