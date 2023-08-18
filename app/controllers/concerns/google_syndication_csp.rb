# frozen_string_literal: true

module GoogleSyndicationCSP
  extend ActiveSupport::Concern

  ALLOWED_SRC = ['*.google.com/pagead/landing', 'pagead2.googlesyndication.com/pagead/landing'].freeze

  included do
    content_security_policy do |policy|
      next unless helpers.google_tag_manager_enabled? || policy.directives.present?

      connect_src_values = Array.wrap(
        policy.directives['connect-src'] || policy.directives['default-src']
      )

      connect_src_values.concat(ALLOWED_SRC) if helpers.google_tag_manager_enabled?

      policy.connect_src(*connect_src_values.uniq)
    end
  end
end
