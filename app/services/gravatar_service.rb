class GravatarService
  def execute(email, size = nil, scale = 2, username: nil)
    return unless Gitlab::CurrentSettings.gravatar_enabled?

    identifier = email.presence || username.presence
    return unless identifier

    hash = Digest::MD5.hexdigest(identifier.strip.downcase)
    size = 40 unless size && size > 0

    sprintf gravatar_url,
      hash: hash,
      size: size * scale,
      email: ERB::Util.url_encode(email&.strip || ''),
      username: ERB::Util.url_encode(username&.strip || '')
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
