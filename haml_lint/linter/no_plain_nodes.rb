# frozen_string_literal: true

require 'active_support/core_ext/array/grouping'

module HamlLint
  class Linter
    class NoPlainNodes < Linter
      include ::HamlLint::LinterRegistry

      def visit_tag(node)
        if inline_plain_node?(node)
          check_inline(node)
        elsif !node.script.empty?
          check_script(node)
        else
          check(node)
        end
      end

      private

      def check(node)
        text_in_node(node).each { |string| record(node, string) }
      end

      def check_inline(node)
        text = inline_text(node)
        record(node, text) unless text.empty?
      end

      def check_script(node)
        text = inline_text(node)
        record(node, text) unless text.start_with?('=') || text.empty?
      end

      # Build an array of all strings in child text nodes.
      # non text nodes are nil, where we'll split the sentences.
      def text_in_node(node)
        texts = node.children.map do |child|
          child.text.strip if text_node?(child)
        end

        texts.split(nil).map { |sentence| sentence.join(' ') unless sentence.empty? }.compact
      end

      # Removes a node's attributes and tag from the source code,
      # returning the inline text of a node.
      def inline_text(node)
        text = node.source_code.gsub("%#{node.tag_name}", '')

        attributes = node.attributes_source.map(&:last)
        attributes.each { |attribute| text = text.gsub(attribute, '') }

        text = strip_html_entities(text)
        text.strip
      end

      def record(node, string)
        record_lint(node, message(string))
      end

      def message(string)
        "`#{string}` is a plain node. Please use an i18n method like `#{fixed(string)}`"
      end

      def fixed(string)
        "= _('#{string}')"
      end

      def inline_plain_node?(node)
        node.children.empty? && node.script.empty?
      end

      def plain_node?(node)
        node.is_a?(::HamlLint::Tree::PlainNode)
      end

      def text_node?(node)
        return false unless plain_node?(node)

        text = strip_html_entities(node.text)
        !text.empty?
      end

      def strip_html_entities(text)
        text.gsub(/&([a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});/i, "")
      end
    end
  end
end
