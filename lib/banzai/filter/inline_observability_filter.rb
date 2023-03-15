# frozen_string_literal: true

module Banzai
  module Filter
    class InlineObservabilityFilter < ::Banzai::Filter::InlineEmbedsFilter
      include Gitlab::Utils::StrongMemoize

      def call
        return doc unless Gitlab::Observability.enabled?(group)

        super
      end

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
        "descendant-or-self::a[starts-with(@href, '#{gitlab_domain}/groups/') and contains(@href,'/-/observability/')]"
      end

      # Creates a new element based on the parameters
      # obtained from the target link
      def element_to_embed(node)
        url = node['href']

        embeddable_url = extract_embeddable_url(url)
        create_element(embeddable_url) if embeddable_url
      end

      private

      def extract_embeddable_url(url)
        strong_memoize_with(:embeddable_url, url) do
          Gitlab::Observability.embeddable_url(url)
        end
      end

      def group
        context[:group] || context[:project]&.group
      end
    end
  end
end
