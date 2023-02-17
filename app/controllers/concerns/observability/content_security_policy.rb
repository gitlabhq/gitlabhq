# frozen_string_literal: true

module Observability
  module ContentSecurityPolicy
    extend ActiveSupport::Concern

    included do
      content_security_policy_with_context do |p|
        current_group = if defined?(group)
                          group
                        else
                          defined?(project) ? project&.group : nil
                        end

        next if p.directives.blank? || !Feature.enabled?(:observability_group_tab, current_group)

        default_frame_src = p.directives['frame-src'] || p.directives['default-src']

        # When ObservabilityUI is not authenticated, it needs to be able
        # to redirect to the GL sign-in page, hence '/users/sign_in' and '/oauth/authorize'
        frame_src_values = Array.wrap(default_frame_src) | [
          Gitlab::Observability.observability_url,
          Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/users/sign_in'),
          Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/oauth/authorize')
        ]

        p.frame_src(*frame_src_values)
      end
    end
  end
end
