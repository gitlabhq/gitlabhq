# frozen_string_literal: true

module WebIdeCSP
  extend ActiveSupport::Concern

  included do
    before_action :include_web_ide_csp

    # We want to include frames from `/assets/webpack` of the request's host to
    # support URL flexibility with the Web IDE.
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118875
    def include_web_ide_csp
      return if request.content_security_policy.directives.blank?

      base_uri = URI(request.url)
      base_uri.path = ::Gitlab.config.gitlab.relative_url_root || '/'
      # `.path +=` handles combining `x/` and `/foo`
      base_uri.path += '/assets/webpack/'
      webpack_url = base_uri.to_s

      default_src = Array(request.content_security_policy.directives['default-src'] || [])
      request.content_security_policy.directives['frame-src'] ||= default_src
      request.content_security_policy.directives['frame-src'].concat([webpack_url, 'https://*.vscode-cdn.net/'])

      request.content_security_policy.directives['worker-src'] ||= default_src
      request.content_security_policy.directives['worker-src'].concat([webpack_url])
    end
  end
end
