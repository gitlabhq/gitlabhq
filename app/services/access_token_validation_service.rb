class AccessTokenValidationService
  # Results:
  VALID = :valid
  EXPIRED = :expired
  REVOKED = :revoked
  INSUFFICIENT_SCOPE = :insufficient_scope

  attr_reader :token, :request

  def initialize(token, request: nil)
    @token = token
    @request = request
  end

  def validate(scopes: [])
    if token.expired?
      return EXPIRED

    elsif token.revoked?
      return REVOKED

    elsif !self.include_any_scope?(scopes)
      return INSUFFICIENT_SCOPE

    else
      return VALID
    end
  end

  # True if the token's scope contains any of the passed scopes.
  def include_any_scope?(scopes)
    if scopes.blank?
      true
    else
      # Remove any scopes whose `if` condition does not return `true`
      scopes = scopes.reject { |scope| scope[:if].presence && !scope[:if].call(request) }

      # Check whether the token is allowed access to any of the required scopes.
      passed_scope_names = scopes.map { |scope| scope[:name].to_sym }
      token_scope_names = token.scopes.map(&:to_sym)
      Set.new(passed_scope_names).intersection(Set.new(token_scope_names)).present?
    end
  end
end
