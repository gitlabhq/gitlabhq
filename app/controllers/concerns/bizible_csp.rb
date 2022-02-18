# frozen_string_literal: true

module BizibleCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next unless helpers.bizible_enabled? || policy.directives.present?

      default_script_src = policy.directives['script-src'] || policy.directives['default-src']
      script_src_values = Array.wrap(default_script_src) | ["'unsafe-eval'", 'https://cdn.bizible.com/scripts/bizible.js']
      policy.script_src(*script_src_values)
    end
  end
end
