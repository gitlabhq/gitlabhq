# frozen_string_literal: true

module WebIdeCSP
  extend ActiveSupport::Concern

  included do
    before_action :include_web_ide_csp
  end

  # We want to include frames from `/assets/webpack` of the request's host to
  # support URL flexibility with the Web IDE.
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118875
  def include_web_ide_csp
    return if request.content_security_policy.directives.blank?

    base_uri = URI(request.url)
    base_uri.path = ::Gitlab.config.gitlab.relative_url_root || '/'
    # note: `.path +=` handles combining trailing and leading slashes (e.g. `x/` and `/foo`)
    base_uri.path += '/assets/webpack/'
    # note: this fixes a browser console warning where CSP included query params
    base_uri.query = nil
    webpack_url = base_uri.to_s

    default_src = Array(request.content_security_policy.directives['default-src'] || [])
    request.content_security_policy.directives['frame-src'] ||= default_src
    request.content_security_policy.directives['frame-src'].concat([webpack_url, 'https://*.web-ide.gitlab-static.net/'])

    request.content_security_policy.directives['worker-src'] ||= default_src
    request.content_security_policy.directives['worker-src'].concat([webpack_url])
  end
end

WebIdeCSP.prepend_mod_with('WebIdeCSP')
