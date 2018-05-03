module InternalRedirect
  prepend EE::InternalRedirect
  extend ActiveSupport::Concern

  def safe_redirect_path(path)
    return unless path
    # Verify that the string starts with a `/` but not a double `/`.
    return unless path =~ %r{^/\w.*$}

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

  def host_allowed?(uri)
    uri.host == request.host &&
      uri.port == request.port
  end

  def full_path_for_uri(uri)
    path_with_query = [uri.path, uri.query].compact.join('?')
    [path_with_query, uri.fragment].compact.join("#")
  end
end
