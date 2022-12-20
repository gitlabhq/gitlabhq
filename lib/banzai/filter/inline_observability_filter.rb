# frozen_string_literal: true

module Banzai
  module Filter
    class InlineObservabilityFilter < ::Banzai::Filter::InlineEmbedsFilter
      # Placeholder element for the frontend to use as an
      # injection point for observability.
      def create_element(url)
        doc.document.create_element(
          'div',
          class: 'js-render-observability',
          'data-frame-url': url
        )
      end

      # Search params for selecting observability links.
      def xpath_search
        "descendant-or-self::a[starts-with(@href, '#{Gitlab::Observability.observability_url}')]"
      end

      # Creates a new element based on the parameters
      # obtained from the target link
      def element_to_embed(node)
        url = node['href']

        create_element(url)
      end
    end
  end
end
