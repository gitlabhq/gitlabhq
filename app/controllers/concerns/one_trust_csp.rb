# frozen_string_literal: true

module OneTrustCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next unless helpers.one_trust_enabled? || policy.directives.present?

      default_script_src = policy.directives['script-src'] || policy.directives['default-src']
      script_src_values = Array.wrap(default_script_src) | ["'unsafe-eval'", 'https://cdn.cookielaw.org', 'https://*.onetrust.com']
      policy.script_src(*script_src_values)

      default_connect_src = policy.directives['connect-src'] || policy.directives['default-src']
      connect_src_values = Array.wrap(default_connect_src) | ['https://cdn.cookielaw.org', 'https://*.onetrust.com']
      policy.connect_src(*connect_src_values)
    end
  end
end
