module OauthHelper
  def ldap_enabled?
    Devise.omniauth_providers.include?(:ldap)
  end

  def default_providers
    [:openid, :twitter, :github, :google_oauth2, :ldap]
  end

  def enabled_oauth_providers
    Devise.omniauth_providers
  end

  def enabled_social_providers
    enabled_oauth_providers.select do |name|
      [:openid, :twitter, :github, :google_oauth2].include?(name.to_sym)
    end
  end
end
