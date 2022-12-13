# rubocop:disable Naming/FileName
# frozen_string_literal: true

module VSCodeCDNCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next if policy.directives.blank?

      default_src = Array(policy.directives['default-src'] || [])
      policy.directives['frame-src'] ||= default_src
      policy.directives['frame-src'].concat(['https://*.vscode-cdn.net/'])
    end
  end
end
# rubocop:enable Naming/FileName
