class GravatarService
  include Gitlab::CurrentSettings

  def execute(email, size = nil, scale = 2)
    if current_application_settings.gravatar_enabled? && email.present?
      size = 40 if size.nil? || size <= 0

      sprintf gravatar_url,
        hash: Digest::MD5.hexdigest(email.strip.downcase),
        size: size * scale,
        email: email.strip
    end
  end

  def gitlab_config
    Gitlab.config.gitlab
  end

  def gravatar_config
    Gitlab.config.gravatar
  end

  def gravatar_url
    if gitlab_config.https
      gravatar_config.ssl_url
    else
      gravatar_config.plain_url
    end
  end
end
