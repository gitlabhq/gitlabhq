# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML filter that converts relative urls into absolute ones.
    class AbsoluteLinkFilter < HTML::Pipeline::Filter
      CSS   = 'a.gfm'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        return doc unless context[:only_path] == false

        doc.xpath(XPATH).each do |el|
          process_link_attr el.attribute('href')
        end

        doc
      end

      protected

      def process_link_attr(html_attr)
        return if html_attr.blank?
        return if html_attr.value.start_with?('//')

        uri = URI(html_attr.value)
        html_attr.value = absolute_link_attr(uri) if uri.relative?
      rescue URI::Error
        # noop
      end

      def absolute_link_attr(uri)
        # Here we really want to expand relative path to absolute path
        URI.join(Gitlab.config.gitlab.url, uri).to_s
      end
    end
  end
end
