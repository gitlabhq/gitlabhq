# frozen_string_literal: true

module Kramdown
  module Parser
    # Parses an Atlassian Document Format (ADF) json into a
    # Kramdown AST tree, for conversion to another format.
    # The primary goal is to convert in GitLab Markdown.
    #
    # This parser does NOT resolve external resources, such as media/attachments.
    # A special url is generated for media based on the id, for example
    #   ![jira-10050-field-description](adf-media://79411c6b-50e0-477f-b4ed-ac3a5887750c)
    # so that a later filter/process can resolve those.
    #
    # @see https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/ ADF Document Structure
    # @see https://developer.atlassian.com/cloud/jira/platform/apis/document/playground/ ADF Playground
    # @see https://developer.atlassian.com/cloud/jira/platform/apis/document/viewer/ ADF Viewer
    class AtlassianDocumentFormat < Kramdown::Parser::Base
      unless defined?(TOP_LEVEL_BLOCK_NODES)
        TOP_LEVEL_BLOCK_NODES = %w[blockquote
                                   bulletList
                                   codeBlock
                                   heading
                                   mediaGroup
                                   mediaSingle
                                   orderedList
                                   panel
                                   paragraph
                                   rule
                                   table].freeze

        CHILD_BLOCK_NODES =     %w[listItem
                                   media
                                   table_cell
                                   table_header
                                   table_row].freeze

        INLINE_NODES =          %w[emoji
                                   hardBreak
                                   inlineCard
                                   mention
                                   text].freeze

        MARKS =                 %w[code
                                   em
                                   link
                                   strike
                                   strong
                                   subsup
                                   textColor
                                   underline].freeze

        TABLE_CELL_NODES =      %w[blockquote
                                   bulletList
                                   codeBlock
                                   heading
                                   mediaGroup
                                   orderedList
                                   panel
                                   paragraph
                                   rule].freeze

        LIST_ITEM_NODES =       %w[bulletList
                                   codeBlock
                                   mediaSingle
                                   orderedList
                                   paragraph].freeze

        PANEL_NODES =           %w[bulletList
                                   heading
                                   orderedList
                                   paragraph].freeze

        PANEL_EMOJIS =          { info: ':information_source:',
                                  note: ':notepad_spiral:',
                                  warning: ':warning:',
                                  success: ':white_check_mark:',
                                  error: ':octagonal_sign:' }.freeze

        # The default language for code blocks is `java`, as indicated in
        # You can't change the default in Jira.  There was a comment that indicated
        # Confluence can set the default language.
        # @see https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=advanced&_ga=2.5135221.773220073.1591894917-438867908.1591894917
        # @see https://jira.atlassian.com/browse/JRASERVER-29184?focusedCommentId=832255&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-832255
        CODE_BLOCK_DEFAULT_LANGUAGE = 'java'
      end

      def parse
        ast = Gitlab::Json.parse(@source)

        validate_document(ast)

        process_content(@root, ast, TOP_LEVEL_BLOCK_NODES)
      rescue ::JSON::ParserError => e
        msg = 'Invalid Atlassian Document Format JSON'
        Gitlab::AppLogger.error msg
        Gitlab::AppLogger.error e

        raise ::Kramdown::Error, msg
      end

      def process_content(element, ast_node, allowed_types)
        ast_node['content'].each do |node|
          next unless allowed_types.include?(node['type'])

          public_send("process_#{node['type'].underscore}", element, node) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def process_blockquote(element, ast_node)
        new_element = Element.new(:blockquote)
        element.children << new_element

        process_content(new_element, ast_node, TOP_LEVEL_BLOCK_NODES)
      end

      def process_bullet_list(element, ast_node)
        new_element = Element.new(:ul)
        element.children << new_element

        process_content(new_element, ast_node, %w[listItem])
      end

      def process_code_block(element, ast_node)
        code_text = gather_text(ast_node)
        lang = ast_node.dig('attrs', 'language') || CODE_BLOCK_DEFAULT_LANGUAGE

        element.children << Element.new(:codeblock, code_text, {}, { lang: lang })
      end

      def process_emoji(element, ast_node)
        emoji = ast_node.dig('attrs', 'text') || ast_node.dig('attrs', 'shortName')
        return unless emoji

        add_text(emoji, element, :text)
      end

      def process_hard_break(element, ast_node)
        element.children << Element.new(:br)
      end

      def process_heading(element, ast_node)
        level = ast_node.dig('attrs', 'level').to_i.clamp(1, 6)
        options = { level: level }
        new_element = Element.new(:header, nil, nil, options)
        element.children << new_element

        process_content(new_element, ast_node, INLINE_NODES)
        extract_element_text(new_element, new_element.options[:raw_text] = +'')
      end

      def process_inline_card(element, ast_node)
        url  = ast_node.dig('attrs', 'url')
        data = ast_node.dig('attrs', 'data')

        if url
          # we don't pull a description from the link and create a panel,
          # just convert to a normal link
          new_element = Element.new(:text, url)
          element.children << wrap_element(new_element, :a, nil, { 'href' => url })
        elsif data
          # data is JSONLD (https://json-ld.org/), so for now output
          # as a codespan of text, with `adf-inlineCard: ` at the start
          text = "adf-inlineCard: #{data}"
          element.children << Element.new(:codespan, text, nil, { lang: 'adf-inlinecard' })
        end
      end

      def process_list_item(element, ast_node)
        new_element = Element.new(:li)
        element.children << new_element

        process_content(new_element, ast_node, LIST_ITEM_NODES)
      end

      def process_media(element, ast_node)
        media_url = "adf-media://#{ast_node['attrs']['id']}"

        case ast_node['attrs']['type']
        when 'file'
          attrs = { 'src' => media_url, 'alt' => ast_node['attrs']['collection'] }
          media_element = Element.new(:img, nil, attrs)
        when 'link'
          attrs = { 'href' => media_url }
          media_element = wrap_element(Element.new(:text, media_url), :a, nil, attrs)
        end

        media_element = wrap_element(media_element, :p)
        element.children << media_element
      end

      # wraps a single media element.
      # Currently ignore attrs.layout and attrs.width
      def process_media_single(element, ast_node)
        new_element = Element.new(:p)
        element.children << new_element

        process_content(new_element, ast_node, %w[media])
      end

      # wraps a group media element.
      # Currently ignore attrs.layout and attrs.width
      def process_media_group(element, ast_node)
        ul_element = Element.new(:ul)
        element.children << ul_element

        ast_node['content'].each do |node|
          next unless node['type'] == 'media'

          li_element = Element.new(:li)
          ul_element.children << li_element

          process_media(li_element, node)
        end
      end

      def process_mention(element, ast_node)
        # Make it `@adf-mention:` since there is no guarantee that it is
        # a valid username in our system.  This gives us an
        # opportunity to replace it later. Mention name can have
        # spaces, so double quote it
        mention_text = ast_node.dig('attrs', 'text')&.delete('@')
        mention_text = %("#{mention_text}") if mention_text&.include?(' ')
        mention_text = %(@adf-mention:#{mention_text})

        add_text(mention_text, element, :text)
      end

      def process_ordered_list(element, ast_node)
        # `attrs.order` is not supported in the Kramdown AST
        new_element = Element.new(:ol)
        element.children << new_element

        process_content(new_element, ast_node, %w[listItem])
      end

      # since we don't have something similar, then put <hr> around it and
      # add a bolded status text (eg: "Error:") to the front of it.
      def process_panel(element, ast_node)
        panel_type = ast_node.dig('attrs', 'panelType')
        return unless %w[info note warning success error].include?(panel_type)

        panel_header_text = "#{PANEL_EMOJIS[panel_type.to_sym]} "
        panel_header_element = Element.new(:text, panel_header_text)

        new_element = Element.new(:blockquote)
        new_element.children << panel_header_element
        element.children << new_element

        process_content(new_element, ast_node, PANEL_NODES)
      end

      def process_paragraph(element, ast_node)
        new_element = Element.new(:p)
        element.children << new_element

        process_content(new_element, ast_node, INLINE_NODES)
      end

      def process_rule(element, ast_node)
        element.children << Element.new(:hr)
      end

      def process_table(element, ast_node)
        table = Element.new(:table, nil, nil, { alignment: [:default, :default] })
        element.children << table

        tbody = Element.new(:tbody)
        table.children << tbody

        process_content(tbody, ast_node, %w[tableRow])
      end

      # we ignore the attributes, attrs.background, attrs.colspan,
      # attrs.colwidth, and attrs.rowspan
      def process_table_cell(element, ast_node)
        new_element = Element.new(:td)
        element.children << new_element

        process_content(new_element, ast_node, TABLE_CELL_NODES)
      end

      # we ignore the attributes, attrs.background, attrs.colspan,
      # attrs.colwidth, and attrs.rowspan
      def process_table_header(element, ast_node)
        new_element = Element.new(:th)
        element.children << new_element

        process_content(new_element, ast_node, TABLE_CELL_NODES)
      end

      def process_table_row(element, ast_node)
        new_element = Element.new(:tr)
        element.children << new_element

        process_content(new_element, ast_node, %w[tableHeader tableCell])
      end

      def process_text(element, ast_node)
        new_element = Element.new(:text, ast_node['text'])
        new_element = apply_marks(new_element, ast_node, MARKS)
        element.children << new_element
      end

      private

      def validate_document(ast)
        return if ast['type'] == 'doc'

        raise ::JSON::ParserError, 'missing doc node'
      end

      # ADF marks are an attribute on the node.  For kramdown,
      # we have to wrap the node with an element for the mark.
      def apply_marks(element, ast_node, allowed_types)
        return element unless ast_node['marks']

        new_element = element

        ast_node['marks'].each do |mark|
          next unless allowed_types.include?(mark['type'])

          case mark['type']
          when 'code'
            new_element = Element.new(:codespan, ast_node['text'])
          when 'em'
            new_element = wrap_element(new_element, :em)
          when 'link'
            attrs = { 'href' => mark.dig('attrs', 'href') }
            attrs['title'] = mark.dig('attrs', 'title')
            new_element = wrap_element(new_element, :a, nil, attrs)
          when 'strike'
            new_element = wrap_element(new_element, :html_element, 'del', {}, category: :span)
          when 'strong'
            new_element = wrap_element(new_element, :strong)
          when 'subsup'
            type = mark.dig('attrs', 'type')

            case type
            when 'sub'
              new_element = wrap_element(new_element, :html_element, 'sub', {}, category: :span)
            when 'sup'
              new_element = wrap_element(new_element, :html_element, 'sup', {}, category: :span)
            else
              next
            end
          when 'textColor'
            color = mark.dig('attrs', 'color')
            new_element = wrap_element(new_element, :html_element, 'span', { color: color }, category: :span)
          when 'underline'
            new_element = wrap_element(new_element, :html_element, 'u', {}, category: :span)
          else
            next
          end
        end

        new_element
      end

      def wrap_element(element, type, *args)
        wrapper = Element.new(type, *args)
        wrapper.children << element
        wrapper
      end

      def extract_element_text(element, raw)
        raw << element.value.to_s if element.type == :text
        element.children.each { |c| extract_element_text(c, raw) }
      end

      def gather_text(ast_node)
        ast_node['content'].inject('') do |memo, node|
          node['type'] == 'text' ? (memo + node['text']) : memo
        end
      end

      def method_missing(method, *args)
        raise NotImplementedError, "method `#{method}` not implemented yet"
      end
    end
  end
end
