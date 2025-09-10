# frozen_string_literal: true

module Authz
  class GranularScopeService
    def initialize(personal_access_token)
      @personal_access_token = personal_access_token
    end

    def add_granular_scopes(granular_scopes)
      scopes_array = Array(granular_scopes)

      scopes_array.each do |granular_scope|
        validation_result = validate_unique_namespace(granular_scope)
        return validation_result if validation_result&.error?
      end

      scopes_array.each do |granular_scope| # rubocop:disable Style/CombinableLoops -- Intentionally separate: validate all first, then build
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

    def validate_unique_namespace(granular_scope)
      return unless namespace_already_exists?(granular_scope.namespace_id)

      error_message = if granular_scope.namespace_id
                        s_('PersonalAccessToken|The token cannot have multiple granular scopes for the same namespace')
                      else
                        s_('PersonalAccessToken|The token cannot have multiple instance-level granular scopes')
                      end

      ServiceResponse.error(message: error_message)
    end

    def namespace_already_exists?(namespace_id)
      check_persisted_scopes(namespace_id) || check_built_scopes(namespace_id)
    end

    def check_persisted_scopes(namespace_id)
      if personal_access_token.granular_scopes.loaded?
        personal_access_token.granular_scopes.any? { |gs| gs.namespace_id == namespace_id }
      else
        personal_access_token.granular_scopes.with_namespace(namespace_id).exists?
      end
    end

    def check_built_scopes(namespace_id)
      personal_access_token.personal_access_token_granular_scopes
        .select(&:new_record?)
        .any? { |join| join.granular_scope&.namespace_id == namespace_id }
    end
  end
end
