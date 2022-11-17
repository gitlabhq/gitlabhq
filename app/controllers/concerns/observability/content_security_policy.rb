# frozen_string_literal: true

module Observability
  module ContentSecurityPolicy
    extend ActiveSupport::Concern

    included do
      content_security_policy do |p|
        next if p.directives.blank? || Gitlab::Observability.observability_url.blank?

        default_frame_src = p.directives['frame-src'] || p.directives['default-src']

        # When ObservabilityUI is not authenticated, it needs to be able
        # to redirect to the GL sign-in page, hence 'self'
        frame_src_values = Array.wrap(default_frame_src) | [Gitlab::Observability.observability_url, "'self'"]

        p.frame_src(*frame_src_values)
      end
    end
  end
end
