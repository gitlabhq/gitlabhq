# frozen_string_literal: true

module Authz
  class GranularScopeService
    def initialize(personal_access_token)
      @personal_access_token = personal_access_token
    end

    def add_granular_scopes(granular_scopes)
      scopes_array = Array(granular_scopes)

      duplicate = GranularScopes::UniquenessCheck
        .new(scopes_array, existing_scopes: existing_scopes)
        .first_duplicate
      return duplicate_error(duplicate) if duplicate

      scopes_array.each do |granular_scope|
        granular_scope.organization_id = personal_access_token.organization_id

        personal_access_token.personal_access_token_granular_scopes.build(
          granular_scope: granular_scope,
          organization_id: personal_access_token.organization_id
        )
      end

      personal_access_token.save! if personal_access_token.persisted?

      ServiceResponse.success(payload: { granular_scopes: scopes_array })
    end

    private

    attr_reader :personal_access_token

    def existing_scopes
      join_rows = personal_access_token.personal_access_token_granular_scopes.to_a
      ActiveRecord::Associations::Preloader.new(records: join_rows, associations: :granular_scope).call

      join_rows.map(&:granular_scope)
    end

    def duplicate_error(granular_scope)
      message = if granular_scope.namespace_id
                  s_('PersonalAccessToken|The token cannot have multiple granular scopes for the same namespace')
                else
                  s_('PersonalAccessToken|The token cannot have multiple granular scopes with the same access level')
                end

      ServiceResponse.error(message: message)
    end
  end
end
