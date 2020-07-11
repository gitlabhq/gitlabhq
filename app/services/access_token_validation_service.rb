# frozen_string_literal: true

class AccessTokenValidationService
  # Results:
  VALID = :valid
  EXPIRED = :expired
  REVOKED = :revoked
  INSUFFICIENT_SCOPE = :insufficient_scope
  IMPERSONATION_DISABLED = :impersonation_disabled

  attr_reader :token, :request

  def initialize(token, request: nil)
    @token = token
    @request = request
  end

  def validate(scopes: [])
    if token.expired?
      EXPIRED

    elsif token.revoked?
      REVOKED

    elsif !self.include_any_scope?(scopes)
      INSUFFICIENT_SCOPE

    elsif token.respond_to?(:impersonation) &&
        token.impersonation &&
        !Gitlab.config.gitlab.impersonation_enabled
      IMPERSONATION_DISABLED

    else
      VALID
    end
  end

  # True if the token's scope contains any of the passed scopes.
  def include_any_scope?(required_scopes)
    if required_scopes.blank?
      true
    else
      # We're comparing each required_scope against all token scopes, which would
      # take quadratic time. This consideration is irrelevant here because of the
      # small number of records involved.
      # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12300/#note_33689006
      token_scopes = token.scopes.map(&:to_sym)

      required_scopes.any? do |scope|
        scope = API::Scope.new(scope) unless scope.is_a?(API::Scope)
        scope.sufficient?(token_scopes, request)
      end
    end
  end
end
