# frozen_string_literal: true

module OauthApplicationsHelper
  # Returns the displayable scope string for a row in the Authorized
  # Applications table, which can be either an OauthAccessToken (#scopes
  # is a Doorkeeper::OAuth::Scopes) or an Authn::OauthConsent (#granted_scopes
  # is an Array).
  def authorized_record_scopes(record)
    return record.granted_scopes.join(' ') if record.respond_to?(:granted_scopes)

    record.scopes.to_s
  end
end
