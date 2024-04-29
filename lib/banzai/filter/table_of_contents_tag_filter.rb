# frozen_string_literal: true

module Banzai
  module Filter
    # Using `[[_TOC_]]` or `[TOC]` (both case insensitive), inserts a Table of Contents list.
    #
    # `[[_TOC_]]` is based on the Gollum syntax. This way we have
    # some consistency between with wiki and normal markdown.
    # The support for this has been removed from GollumTagsFilter
    #
    # `[toc]` is a generally accepted form, used by Typora for example.
    #
    # Based on Banzai::Filter::GollumTagsFilter
    class TableOfContentsTagFilter < HTML::Pipeline::Filter
      TEXT_QUERY = %q(descendant-or-self::text()[ancestor::p and contains(translate(., 'TOC', 'toc'), 'toc')])

      HEADER_CSS   = 'h1, h2, h3, h4, h5, h6'
      HEADER_XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(HEADER_CSS).freeze

      def call
        return doc if context[:no_header_anchors]

        doc.xpath(TEXT_QUERY).each do |node|
          if toc_tag?(node)
            # Support [TOC] / [toc] tags, which don't have a wrapping <em>-tag
            process_toc_tag(node)
          elsif toc_tag_em?(node)
            # Support Gollum like ToC tag (`[[_TOC_]]` / `[[_toc_]]`), which will be converted
            # into `[[<em>TOC</em>]]` by the markdown filter, so it
            # needs special-case handling
            process_toc_tag_em(node)
          end
        end

        doc
      end

      private

      # Replace an entire `[[<em>TOC</em>]]` node
      def process_toc_tag_em(node)
        process_toc_tag(node.parent)
      end

      # Replace an entire `[TOC]` node
      def process_toc_tag(node)
        build_toc if Feature.enabled?(:native_header_anchors)

        # we still need to go one step up to also replace the surrounding <p></p>
        node.parent.replace(result[:toc].presence || '')
      end

      def toc_tag_em?(node)
        node.content.casecmp?('toc') &&
          node.parent.name == 'em' &&
          node.parent.parent.text.casecmp?('[[toc]]')
      end

      def toc_tag?(node)
        node.parent.text.casecmp?('[toc]')
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
