module OauthHelper
  def ldap_enabled?
    Gitlab.config.ldap.enabled
  end

  def default_providers
    [:twitter, :github, :gitlab, :bitbucket, :google_oauth2, :ldap]
  end

  def enabled_oauth_providers
    Devise.omniauth_providers
  end

  def enabled_social_providers
    enabled_oauth_providers.select do |name|
      [:twitter, :gitlab, :github, :bitbucket, :google_oauth2].include?(name.to_sym)
    end
  end

  def additional_providers
    enabled_oauth_providers.reject{|provider| provider.to_s.starts_with?('ldap')}
  end
  
  extend self
end
