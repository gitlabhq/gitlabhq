# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by Markdown. Allows styling of links and usage of line breaks.
    #
    # Extends Banzai::Filter::BaseSanitizationFilter with specific rules.
    class BroadcastMessageSanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      def customize_whitelist(whitelist)
        whitelist[:elements].push('br')

        whitelist[:attributes]['a'].push('class', 'style')

        whitelist[:css] = { properties: %w(color border background padding margin text-decoration) }

        whitelist
      end
    end
  end
end
