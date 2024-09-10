# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter to modify the attributes of external links.
    # This is considered a sanitization filter.
    class ExternalLinkFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler

      SCHEMES      = ['http', 'https', nil].freeze
      RTLO         = "\u202E"
      ENCODED_RTLO = '%E2%80%AE'

      def call
        links.each do |node|
          # URI.parse does stricter checking on the url than Addressable,
          # such as on `mailto:` links. Since we've been using it, do an
          # initial parse for validity and then use Addressable
          # for IDN support, etc
          uri = uri_strict(node_src(node))
          if uri
            node.set_attribute(node_src_attribute(node), uri.to_s)
            addressable_uri = addressable_uri(node_src(node))
          else
            addressable_uri = nil
          end

          next if internal_url?(addressable_uri)

          punycode_autolink_node!(addressable_uri, node)
          sanitize_link_text!(node)
          add_malicious_tooltip!(addressable_uri, node)
          add_nofollow!(addressable_uri, node)
        end

        doc
      end

      private

      def render_timeout
        SANITIZATION_RENDER_TIMEOUT
      end

      # Since this filter does a level of sanitization, we can not return
      # partial un-sanitized results.
      # It's ok to allow any following filters to run since this is safe HTML.
      def returned_timeout_value
        HTML::Pipeline.parse(Banzai::Filter::SanitizeLinkFilter::TIMEOUT_MARKDOWN_MESSAGE)
      end

      # if this is a link to a proxied image, then `src` is already the correct
      # proxied url, so work with the `data-canonical-src`
      def node_src_attribute(node)
        node['data-canonical-src'] ? 'data-canonical-src' : 'href'
      end

      def node_src(node)
        node[node_src_attribute(node)]
      end

      def uri_strict(href)
        URI.parse(href)
      rescue URI::Error
        nil
      end

      def addressable_uri(href)
        Addressable::URI.parse(href)
      rescue Addressable::URI::InvalidURIError
        nil
      end

      def links
        query = 'descendant-or-self::a[@href and not(@href = "")]'
        doc.xpath(query)
      end

      def internal_url?(uri)
        return false if uri.nil?
        # Relative URLs miss a hostname AND a scheme
        return true if !uri.hostname && !uri.scheme

        uri.hostname == internal_url.hostname
      end

      def internal_url
        @internal_url ||= URI.parse(Gitlab.config.gitlab.url)
      end

      # Only replace an autolink with an IDN with it's punycode
      # version if we need emailable links.  Otherwise let it
      # be shown normally and the tooltips will show the
      # punycode version.
      def punycode_autolink_node!(uri, node)
        return unless uri
        return unless context[:emailable_links]

        unencoded_uri_str = Addressable::URI.unencode(node_src(node))

        if unencoded_uri_str == node.content && idn?(uri)
          node.content = uri.normalize
        end
      end

      # escape any right-to-left (RTLO) characters in link text
      def sanitize_link_text!(node)
        node.inner_html = node.inner_html.gsub(RTLO, ENCODED_RTLO)
      end

      # If the domain is an international domain name (IDN),
      # let's expose with a tooltip in case it's intended
      # to be malicious. This is particularly useful for links
      # where the link text is not the same as the actual link.
      # We will continue to show the unicode version of the domain
      # in autolinked link text, which could contain emojis, etc.
      #
      # Also show the tooltip if the url contains the RTLO character,
      # as this is an indicator of a malicious link
      def add_malicious_tooltip!(uri, node)
        if idn?(uri) || has_encoded_rtlo?(uri)
          node.add_class('has-tooltip')
          node.set_attribute('title', uri.normalize)
        end
      end

      def add_nofollow!(uri, node)
        if SCHEMES.include?(uri&.scheme)
          license = true if node.attribute('rel')&.value == 'license'
          node.set_attribute('rel', 'nofollow noreferrer noopener')
          node.kwattr_append('rel', 'license') if license
          node.set_attribute('target', '_blank')
        end
      end

      def idn?(uri)
        uri&.normalized_host&.start_with?('xn--')
      end

      def has_encoded_rtlo?(uri)
        uri&.to_s&.include?(ENCODED_RTLO)
      end
    end
  end
end
