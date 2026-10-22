# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitise HTML produced by Markdown in user bios. Allows only a minimal
    # set of inline elements: no links, no images, and no attributes.
    class UserBioSanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      ALLOWED_ELEMENTS = %w[em strong code].freeze

      def customize_allowlist(allowlist)
        allowlist[:elements] = ALLOWED_ELEMENTS.dup
        allowlist[:attributes] = {}
        allowlist[:protocols] = {}

        allowlist
      end
    end
  end
end
