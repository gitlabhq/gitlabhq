# frozen_string_literal: true

module ZuoraCSP
  extend ActiveSupport::Concern

  ZUORA_URL = 'https://*.zuora.com'

  included do
    content_security_policy do |policy|
      next if policy.directives.blank?

      default_script_src = policy.directives['script-src'] || policy.directives['default-src']
      script_src_values = Array.wrap(default_script_src) | ["'self'", "'unsafe-eval'", ZUORA_URL]

      default_frame_src = policy.directives['frame-src'] || policy.directives['default-src']
      frame_src_values = Array.wrap(default_frame_src) | ["'self'", ZUORA_URL]

      default_child_src = policy.directives['child-src'] || policy.directives['default-src']
      child_src_values = Array.wrap(default_child_src) | ["'self'", ZUORA_URL]

      policy.script_src(*script_src_values)
      policy.frame_src(*frame_src_values)
      policy.child_src(*child_src_values)
    end
  end
end
