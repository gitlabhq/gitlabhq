# frozen_string_literal: true

# Provides safe redirect helpers for controllers that accept user-supplied
# redirect targets (e.g., after login, OAuth callbacks, admin sudo, terms
# acceptance).
#
# A redirect is considered "safe" if it guarantees ALL of the following:
#
# 1. Same-origin - for full URLs, the destination host and port must match
#    the current request (no cross-host or cross-port redirects).
# 2. Relative path - the result is always a bare path (no scheme, no host).
#    Scheme and host are discarded even if the input contains them.
# 3. No protocol injection - inputs that a browser could treat as external
#    or non-HTTP targets (javascript:, data:, //evil.com, etc.) are rejected.
# 4. Parsed, not concatenated - the destination is extracted via URI parsing
#    (path + query + fragment only), not constructed by string manipulation.
#
# Historical context: CVE-2019-18451 was an open redirect bypass on this
# code. The two-layer validation (regex pre-filter + URI parsing) exists
# to defend in depth against bypass attempts.
#
# See also: OWASP Unvalidated Redirects and Forwards Cheat Sheet
# https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html
module InternalRedirect
  extend ActiveSupport::Concern

  # Combined entry point: tries the input as a relative path first, then
  # as a full URL. Always returns a bare path or nil -never a full URL.
  def sanitize_redirect(url_or_path)
    safe_redirect_path(url_or_path) || safe_redirect_path_for_url(url_or_path)
  end

  # Validates a relative path for use as a redirect target.
  #
  # Regex pre-filter ensures the path starts with `/` followed by a hyphen,
  # question mark, or word character. This blocks protocol-relative URLs
  # (//evil.com), backslash escapes (/\evil.com), bare words, and control
  # characters before they reach the URI parser. The URI parser then
  # extracts only path + query + fragment, discarding any scheme or host.
  def safe_redirect_path(path)
    return unless path
    return unless %r{\A/[-?\w]}.match?(path)

    uri = URI(path)
    full_path_for_uri(uri)
  rescue URI::InvalidURIError
    nil
  end

  # Validates a full URL for use as a redirect target by checking that
  # the host and port match the current request, then extracting only
  # the path portion. The result is always a bare path -scheme and host
  # are never included in the return value.
  def safe_redirect_path_for_url(url)
    return unless url

    uri = URI(url)
    safe_redirect_path(full_path_for_uri(uri)) if host_allowed?(uri)
  rescue URI::InvalidURIError
    nil
  end

  # Returns true if the URI's host and port match the current request.
  # Overridden in EE to also allow redirects to registered Geo nodes.
  def host_allowed?(uri)
    uri.host == request.host &&
      uri.port == request.port
  end

  def referer_path(request)
    return unless request.referer.presence

    URI(request.referer).path
  end

  private

  # Extracts path + query + fragment from a parsed URI, discarding scheme
  # and host so the result is always a bare relative path.
  def full_path_for_uri(uri)
    path_with_query = [uri.path, uri.query].compact.join('?')
    [path_with_query, uri.fragment].compact.join("#")
  end
end

InternalRedirect.prepend_mod_with('InternalRedirect')
