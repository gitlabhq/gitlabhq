class GravatarService
  def execute(email, size = nil)
    if gravatar_config.enabled && email.present?
      size = 40 if size.nil? || size <= 0

      sprintf gravatar_url,
        hash: Digest::MD5.hexdigest(email.strip.downcase),
        size: size,
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
