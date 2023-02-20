# frozen_string_literal: true

require 'nokogiri'

module Gitlab
  module Email
    class HtmlToMarkdownParser < Html2Text
      ADDITIONAL_TAGS = %w[em strong img details].freeze
      IMG_ATTRS = %w[alt src].freeze

      def self.convert(html)
        html = fix_newlines(replace_entities(html))
        doc = Nokogiri::HTML(html)

        HtmlToMarkdownParser.new(doc).convert
      end

      def iterate_over(node)
        return super unless ADDITIONAL_TAGS.include?(node.name)

        if node.name == 'img'
          node.keys.each { |key| node.remove_attribute(key) unless IMG_ATTRS.include?(key) } # rubocop:disable Style/HashEachMethods
        end

        Kramdown::Document.new(node.to_html, input: 'html').to_commonmark
      end
    end
  end
end
