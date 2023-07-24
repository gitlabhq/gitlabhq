# frozen_string_literal: true

module PersonalAccessTokens
  class RevokeTokenFamilyService
    def initialize(token)
      @token = token
    end

    def execute
      # A token family is a chain of rotated tokens. Once rotated, the previous
      # token is revoked. As a result, a single token id should be returned by
      # this query.
      # rubocop: disable CodeReuse/ActiveRecord
      token_ids = pat_family.active.pluck_primary_key

      # We create another query based on the previous if any id exists. An
      # alternative is to use a single query, like
      # `pat_family.active.update_all(...)`). However, #update_all ignores
      # the CTE, and tries to revoke *all* active tokens.
      PersonalAccessToken.where(id: token_ids).update_all(revoked: true) if token_ids.any?
      # rubocop: enable CodeReuse/ActiveRecord

      ServiceResponse.success
    end

    private

    attr_reader :token

    def pat_family
      # rubocop: disable CodeReuse/ActiveRecord
      cte = Gitlab::SQL::RecursiveCTE.new(:personal_access_tokens_cte)
      personal_access_token_table = Arel::Table.new(:personal_access_tokens)

      cte << PersonalAccessToken
               .select(
                 'personal_access_tokens.id',
                 'personal_access_tokens.revoked',
                 'personal_access_tokens.expires_at')
               .where(personal_access_token_table[:previous_personal_access_token_id].eq(token.id))
      cte << PersonalAccessToken
               .select(
                 'personal_access_tokens.id',
                 'personal_access_tokens.revoked',
                 'personal_access_tokens.expires_at')
               .from([personal_access_token_table, cte.table])
               .where(personal_access_token_table[:previous_personal_access_token_id].eq(cte.table[:id]))
      PersonalAccessToken.with.recursive(cte.to_arel).from(cte.alias_to(personal_access_token_table))
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
