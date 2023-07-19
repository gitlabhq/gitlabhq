# frozen_string_literal: true

module InternalRedirect
  extend ActiveSupport::Concern

  def safe_redirect_path(path)
    return unless path
    # Verify that the string starts with a `/` and a known route character.
    return unless %r{\A/[-\w].*\z}.match?(path)

    uri = URI(path)
    # Ignore anything path of the redirect except for the path, querystring and,
    # fragment, forcing the redirect within the same host.
    full_path_for_uri(uri)
  rescue URI::InvalidURIError
    nil
  end

  def safe_redirect_path_for_url(url)
    return unless url

    uri = URI(url)
    safe_redirect_path(full_path_for_uri(uri)) if host_allowed?(uri)
  rescue URI::InvalidURIError
    nil
  end

  def sanitize_redirect(url_or_path)
    safe_redirect_path(url_or_path) || safe_redirect_path_for_url(url_or_path)
  end

  def host_allowed?(uri)
    uri.host == request.host &&
      uri.port == request.port
  end

  def full_path_for_uri(uri)
    path_with_query = [uri.path, uri.query].compact.join('?')
    [path_with_query, uri.fragment].compact.join("#")
  end

  def referer_path(request)
    return unless request.referer.presence

    URI(request.referer).path
  end
end

InternalRedirect.prepend_mod_with('InternalRedirect')
