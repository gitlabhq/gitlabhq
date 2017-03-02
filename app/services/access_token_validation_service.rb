class AccessTokenValidationService
  # Results:
  VALID = :valid
  EXPIRED = :expired
  REVOKED = :revoked
  INSUFFICIENT_SCOPE = :insufficient_scope

  attr_reader :token

  def initialize(token)
    @token = token
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
      # Check whether the token is allowed access to any of the required scopes.
      Set.new(scopes).intersection(Set.new(token.scopes)).present?
    end
  end
end
