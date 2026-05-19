# frozen_string_literal: true

module Banzai
  module Filter
    # Using `[[_TOC_]]` or `[TOC]` (both case insensitive) on it's own line,
    # inserts a Table of Contents list.
    #
    # `[[_TOC_]]` is based on the Gollum syntax. This way we have
    # some consistency between wiki and normal markdown.
    # Parser will have converted it into a wikilink.
    #
    # `[toc]` is a generally accepted form, used by Typora for example.
    #
    # Based on Banzai::Filter::GollumTagsFilter
    class TableOfContentsTagFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      OR_SELF = 'descendant-or-self::text()'
      TOC_QUERY = %(#{OR_SELF}[parent::p and starts-with(translate(., '[TOC]', '[toc]'), '[toc]')]).freeze
      GOLLUM_TOC_QUERY =
        %(#{OR_SELF}[ancestor::a[@data-wikilink="true"] and starts-with(translate(., '_TOC_', '_toc_'), '_toc_')])
        .freeze

      HEADER_CSS   = 'h1, h2, h3, h4, h5, h6'
      HEADER_XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(HEADER_CSS).freeze

      def call
        return doc unless MarkdownFilter.glfm_markdown?(context)
        return doc if context[:no_header_anchors]

        doc.xpath(GOLLUM_TOC_QUERY).each do |node|
          process_toc_tag(node.parent) if toc_tag_gollum?(node)
        end

        doc.xpath(TOC_QUERY).each do |node|
          next unless node.parent.children.size == 1 &&
            node.text? &&
            node.content.strip.casecmp?('[toc]')

          process_toc_tag(node)
        end

        doc
      end

      private

      def process_toc_tag(node)
        toc_ul = build_toc
        node.parent.replace(toc_ul || '')
      end

      def toc_tag_gollum?(node)
        node.parent.parent.name == 'p' && node.parent.parent.text.casecmp?('_toc_')
      end

      def build_toc
        return @toc if defined?(@toc)

        header_root = current_header = HeaderNode.new

        doc.xpath(HEADER_XPATH).each do |node|
          header_anchor = node.css('a.anchor').first
          next unless header_anchor

          href = header_anchor[:href].slice(1..)
          current_header = HeaderNode.new(node: node, href: href, previous_header: current_header)
        end

        @toc = build_toc_list(header_root.children, root: true)
      end

      def build_toc_list(children, root: false)
        return if children.empty?

        ul = doc.document.create_element('ul')
        ul['class'] = 'section-nav' if root

        children.each do |child|
          ul.add_child(build_toc_item(child))
        end

        ul
      end

      def build_toc_item(header_node)
        li = doc.document.create_element('li')

        a = doc.document.create_element('a')
        a['href'] = "##{header_node.href}"
        a.content = header_node.text
        li.add_child(a)

        nested = build_toc_list(header_node.children)
        li.add_child(nested) if nested

        li
      end

      class HeaderNode
        attr_reader :node, :href, :parent, :children

        def initialize(node: nil, href: nil, previous_header: nil)
          @node = node
          @href = href
          @children = []

          @parent = find_parent(previous_header)
          @parent.children.push(self) if @parent
        end

        def level
          return 0 unless node

          @level ||= node.name[1].to_i
        end

        def text
          return '' unless node

          @text ||= node.text.strip
        end

        private

        def find_parent(previous_header)
          return unless previous_header

          if level == previous_header.level
            parent = previous_header.parent
          elsif level > previous_header.level
            parent = previous_header
          else
            parent = previous_header
            parent = parent.parent while parent.level >= level
          end

          parent
        end
      end
    end
  end
end
