# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a node for each occurrence of
    # a given link format. To transform references to DB
    # resources in place, prefer to inherit from AbstractReferenceFilter.
    class InlineEmbedsFilter < HTML::Pipeline::Filter
      # Find every relevant link, create a new node based on
      # the link, and insert this node after any html content
      # surrounding the link.
      def call
        return doc if Feature.enabled?(:remove_monitor_metrics)

        doc.xpath(xpath_search).each do |node|
          next unless element = element_to_embed(node)

          # We want this to follow any surrounding content. For example,
          # if a link is inline in a paragraph.
          node.parent.children.last.add_next_sibling(element)
        end

        doc
      end

      # Child class must provide the metrics_dashboard_url.
      #
      # Return a Nokogiri::XML::Element to embed in the
      # markdown which provides a url to the metric_dashboard endpoint where
      # data can be requested through a prometheus proxy. InlineMetricsRedactorFilter
      # is responsible for permissions to see this div (and relies on the class 'js-render-metrics' ).
      def create_element(params)
        doc.document.create_element(
          'div',
          class: 'js-render-metrics',
          'data-dashboard-url': metrics_dashboard_url(params)
        )
      end

      # Implement in child class unless overriding #embed_params
      #
      # Returns the regex pattern used to filter
      # to only matching urls.
      def link_pattern
      end

      # Returns the xpath query string used to select nodes
      # from the html document on which the embed is based.
      #
      # Override to select nodes other than links.
      def xpath_search
        'descendant-or-self::a[@href]'
      end

      # Creates a new element based on the parameters
      # obtained from the target link
      def element_to_embed(node)
        return unless params = embed_params(node)

        create_element(params)
      end

      # Returns a hash of named parameters based on the
      # provided regex with string keys.
      #
      # Override to select nodes other than links.
      def embed_params(node)
        url = node['href']

        link_pattern.match(url) { |m| m.named_captures }
      end

      # Parses query params out from full url string into hash.
      #
      # Ex) 'https://<root>/<project>/<environment>/metrics?title=Title&group=Group'
      #       --> { title: 'Title', group: 'Group' }
      def query_params(url)
        Gitlab::Metrics::Dashboard::Url.parse_query(url)
      end

      # Implement in child class.
      #
      # Provides a full url to request the relevant panels of metric data.
      def metrics_dashboard_url
        raise NotImplementedError
      end

      def gitlab_domain
        ::Gitlab.config.gitlab.url
      end
    end
  end
end
