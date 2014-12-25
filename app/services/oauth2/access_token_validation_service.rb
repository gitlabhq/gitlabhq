module Oauth2::AccessTokenValidationService
  # Results:
  VALID = :valid
  EXPIRED = :expired
  REVOKED = :revoked
  INSUFFICIENT_SCOPE = :insufficient_scope

  class << self
    def validate(token, scopes: [])
      if token.expired?
        return EXPIRED

      elsif token.revoked?
        return REVOKED

      elsif !self.sufficent_scope?(token, scopes)
        return INSUFFICIENT_SCOPE

      else
        return VALID
      end
    end

    protected
    # True if the token's scope is a superset of required scopes,
    # or the required scopes is empty.
    def sufficent_scope?(token, scopes)
      if scopes.blank?
        # if no any scopes required, the scopes of token is sufficient.
        return true
      else
        # If there are scopes required, then check whether
        # the set of authorized scopes is a superset of the set of required scopes
        required_scopes = Set.new(scopes)
        authorized_scopes = Set.new(token.scopes)

        return authorized_scopes >= required_scopes
      end
    end
  end
end