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
      [:saml, :twitter, :gitlab, :github, :bitbucket, :google_oauth2].include?(name.to_sym)
    end
  end

  def additional_providers
    enabled_oauth_providers.reject{|provider| provider.to_s.starts_with?('ldap')}
  end

  def oauth_image_tag(provider, size = 64)
    file_name = "#{provider.to_s.split('_').first}_#{size}.png"
    image_tag(image_path("authbuttons/#{file_name}"), alt: "Sign in with #{provider.to_s.titleize}")
  end

  def oauth_active?(provider)
    current_user.identities.exists?(provider: provider.to_s)
  end

  extend self
end
