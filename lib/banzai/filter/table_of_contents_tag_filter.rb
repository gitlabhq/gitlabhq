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

      # Replace an entire `[TOC]` node
      def process_toc_tag(node)
        build_toc

        # Replace the entire paragraph containing the TOC tag
        node.parent.replace(result[:toc].presence || '')
      end

      def toc_tag_gollum?(node)
        node.parent.parent.name == 'p' && node.parent.parent.text.casecmp?('_toc_')
      end

      def build_toc
        return if result[:toc]

        result[:toc] = +""

        header_root = current_header = HeaderNode.new

        doc.xpath(HEADER_XPATH).each do |node|
          header_anchor = node.css('a.anchor').first
          next unless header_anchor

          # remove leading anchor `#` so we can add it back later
          href = header_anchor[:href].slice(1..)
          current_header = HeaderNode.new(node: node, href: href, previous_header: current_header)
        end

        push_toc(header_root.children, root: true)
      end

      def push_toc(children, root: false)
        return if children.empty?

        klass = ' class="section-nav"' if root

        result[:toc] << "<ul#{klass}>"
        children.each { |child| push_anchor(child) }
        result[:toc] << '</ul>'
      end

      def push_anchor(header_node)
        result[:toc] << %(<li><a href="##{header_node.href}">#{header_node.text}</a>)
        push_toc(header_node.children)
        result[:toc] << '</li>'
      end

      class HeaderNode
        attr_reader :node, :href, :parent, :children

        def initialize(node: nil, href: nil, previous_header: nil)
          @node = node
          @href = CGI.escape(href) if href
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

          @text ||= CGI.escapeHTML(node.text)
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
