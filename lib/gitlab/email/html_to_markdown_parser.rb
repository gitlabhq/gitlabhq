# frozen_string_literal: true

require 'nokogiri'

module Gitlab
  module Email
    class HtmlToMarkdownParser < Html2Text
      extend Gitlab::Utils::Override

      # List of tags to be converted by Markdown.
      #
      # All attributes are removed except for the defined ones.
      #
      #   <tag> => [<attribute to keep>, ...]
      ALLOWED_TAG_ATTRIBUTES = {
        'em' => [],
        'strong' => [],
        'details' => [],
        'img' => %w[alt src]
      }.freeze
      private_constant :ALLOWED_TAG_ATTRIBUTES

      # This redefinition can be removed once https://github.com/soundasleep/html2text_ruby/pull/30
      # is merged and released.
      def self.convert(html)
        html = fix_newlines(replace_entities(html))
        doc = Nokogiri::HTML(html)

        new(doc).convert
      end

      private

      override :iterate_over
      def iterate_over(node)
        allowed_attributes = ALLOWED_TAG_ATTRIBUTES[node.name]
        return super unless allowed_attributes

        remove_attributes(node, allowed_attributes)

        Kramdown::Document.new(node.to_html, input: 'html').to_commonmark
      end

      def remove_attributes(node, allowed_attributes)
        to_remove = (node.keys - allowed_attributes)
        to_remove.each { |key| node.remove_attribute(key) }
      end
    end
  end
end
