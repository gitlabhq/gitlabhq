# frozen_string_literal: true

module GoogleAnalyticsCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next unless helpers.google_tag_manager_enabled? || policy.directives.present?

      # Tag Manager with a Content Security Policy for Google Analytics 4
      # https://developers.google.com/tag-platform/security/guides/csp#google_analytics_4_google_analytics

      default_script_src = policy.directives['script-src'] || policy.directives['default-src']
      script_src_values = Array.wrap(default_script_src) | ['*.googletagmanager.com']
      policy.script_src(*script_src_values)

      default_img_src = policy.directives['img-src'] || policy.directives['default-src']
      img_src_values =
        Array.wrap(default_img_src) |
        [
          '*.google-analytics.com',
          '*.analytics.google.com',
          '*.googletagmanager.com',
          '*.g.doubleclick.net'
        ]
      policy.img_src(*img_src_values)

      default_connect_src = policy.directives['connect-src'] || policy.directives['default-src']
      connect_src_values =
        Array.wrap(default_connect_src) |
        [
          '*.google-analytics.com',
          '*.analytics.google.com',
          '*.googletagmanager.com',
          '*.g.doubleclick.net'
        ]
      policy.connect_src(*connect_src_values)
    end
  end
end
