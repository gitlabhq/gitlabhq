# frozen_string_literal: true

module Observability
  module ContentSecurityPolicy
    extend ActiveSupport::Concern

    included do
      content_security_policy do |p|
        next if p.directives.blank?

        default_frame_src = p.directives['frame-src'] || p.directives['default-src']
        # When Gitlab Observability Backend is not authenticated, it needs to be able
        # to redirect to the GitLab sign-in page, hence '/users/sign_in' and '/oauth/authorize'
        frame_src_values = Array.wrap(default_frame_src) | [
          Gitlab::Observability.observability_url,
          Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/users/sign_in'),
          Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/oauth/authorize')
        ]
        p.frame_src(*frame_src_values)

        default_connect_src = p.directives['connect-src'] || p.directives['default-src']
        connect_src_values =
          Array.wrap(default_connect_src) | [Gitlab::Observability.observability_url]
        p.connect_src(*connect_src_values)
      end
    end
  end
end
