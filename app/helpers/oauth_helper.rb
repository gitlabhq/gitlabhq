module OauthHelper
  def ldap_enabled?
    Devise.omniauth_providers.include?(:ldap)
  end

  def default_providers
    [:twitter, :github, :google_oauth2, :ldap]
  end

  def enabled_oauth_providers
    Devise.omniauth_providers
  end
end
