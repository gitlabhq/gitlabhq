module OauthHelper
  def ldap_enabled?
    Gitlab.config.ldap.enabled
  end

  def default_providers
    [:twitter, :github, :google_oauth2, :ldap]
  end

  def enabled_oauth_providers
    Devise.omniauth_providers
  end

  def enabled_social_providers
    enabled_oauth_providers.select do |name|
      [:twitter, :github, :google_oauth2].include?(name.to_sym)
    end
  end

  def additional_providers
    enabled_oauth_providers.reject{|provider| provider.to_s.starts_with?('ldap')}
  end
end
