require 'ldapavatar_service'

class GravatarService < LDAPAvatarService
  include Gitlab::CurrentSettings

  def initialize
    @img_size, @user_email, @email_hash = nil, nil, nil
  end

  def execute(email, size = nil)
    if current_application_settings.gravatar_enabled? && email.present?
      @img_size   = size.nil? || size <= 0 ? 40 : size
      @user_email = email
      @email_hash = Digest::MD5.hexdigest(@user_email.strip.downcase)

      sprintf lookup_url,
        hash:  @email_hash,
        size:  @img_size,
        email: @user_email.strip
    end
  end

  def gitlab_config
    Gitlab.config.gitlab
  end

  def gravatar_config
    Gitlab.config.gravatar
  end

  # Only queries first defined ldap provider. For EE, if multiple providers are defined
  # then this needs extended to lookup users ldap provider given known user info.
  def provider
    "ldap#{Gitlab.config.ldap.servers.keys.first}"
  end

  def provider_adapter_options
    Gitlab::LDAP::Config.new(provider).adapter_options
  end

  def provider_options
    Gitlab::LDAP::Config.new(provider).options
  end

  def lookup_url
    url = ldap_url if Gitlab::LDAP::Config.enabled? && provider_options['preempt_gravatar_with_ldap']
    url.nil? || defined?(url).nil? ? gravatar_url : url
  end

  def ldap_url
    if lookup_user_avatar_in_ldap
      gitlab_config.https ? provider_options['avatar_secure_url'] : provider_options['avatar_plain_url']
    end
  end

  def gravatar_url
    if gitlab_config.https
      gravatar_config.ssl_url
    else
      gravatar_config.plain_url
    end
  end
end

