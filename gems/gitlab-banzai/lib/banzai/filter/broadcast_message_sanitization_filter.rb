# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by Markdown. Allows styling of links and usage of line breaks.
    #
    # Extends Banzai::Filter::BaseSanitizationFilter with specific rules.
    class BroadcastMessageSanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      def customize_allowlist(allowlist)
        allowlist[:elements].push('br')

        allowlist[:attributes]['a'].push('class', 'style')

        allowlist[:css] = { properties: %w[color border background padding margin text-decoration] }

        allowlist
      end
    end
  end
end
