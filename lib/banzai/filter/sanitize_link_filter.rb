# frozen_string_literal: true

module Banzai
  module Filter
    # Validate links and remove unsafe protocols.
    # This can be intensive, so it was split from BaseSanitizationFilter in order
    # for it to have its own time period.
    class SanitizeLinkFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler
      include Gitlab::Utils::SanitizeNodeLink

      # [href], [src], [data-src], [data-canonical-src]
      CSS = Gitlab::Utils::SanitizeNodeLink::ATTRS_TO_SANITIZE.map { |x| "[#{x}]" }.join(', ')
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      TIMEOUT_MARKDOWN_MESSAGE =
        <<~HTML
          <p>Timeout while sanitizing links - rendering aborted. Please reduce the number of links if possible.</p>
        HTML

      def call
        doc.xpath(self.class::XPATH).each do |el|
          sanitize_unsafe_links({ node: el })
        end

        doc
      end

      private

      def render_timeout
        SANITIZATION_RENDER_TIMEOUT
      end

      # If sanitization times out, we can not return partial un-sanitized results.
      # It's ok to allow any following filters to run since this is safe HTML.
      def returned_timeout_value
        HTML::Pipeline.parse(TIMEOUT_MARKDOWN_MESSAGE)
      end
    end
  end
end
