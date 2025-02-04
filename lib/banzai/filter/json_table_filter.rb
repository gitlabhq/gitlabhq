# frozen_string_literal: true

module Banzai
  module Filter
    # Prepares a `json:table` if it's been tagged as supporting markdown
    #
    # If the `markdown` option is not specfied or a boolean true, then we do
    # nothing and allow the frontend to sanitize it and display it.
    #
    # If `markdown: true` is included in the table, then we
    # - extract the data from the JSON
    # - build a markdown pipe table with the data
    # - run the markdown pipe table through the MarkdownFilter
    # - run the caption through markdown and add as <caption> to table
    # - add the table options as `data-` attributes so the frontend can properly display
    # - note that this filter is handled _before_ the SanitizationFilter, which means
    #   the resulting HTML will get properly sanitized at that point.
    class JsonTableFilter < HTML::Pipeline::Filter
      include Concerns::OutputSafety

      CSS   = '[data-canonical-lang="json"][data-lang-params="table"] > code:only-child'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |node|
          process_json_table(node)
        end

        doc
      end

      private

      attr_reader :fields, :items

      def process_json_table(code_node)
        return if code_node.parent&.parent.nil?

        json = begin
          Gitlab::Json.parse(code_node.text)
        rescue JSON::ParserError
          nil
        end

        # JSON not valid, let the frontend handle this block
        return unless json
        return unless json['markdown']

        @fields = json['fields']
        @items = json['items']

        table = table_header
        table << table_body

        table_context = context.merge(no_sourcepos: true)
        html = Banzai::Filter::MarkdownFilter.new(table, table_context).call

        table_node = Nokogiri::HTML::DocumentFragment.parse(html)
        table_node = table_node.children.first

        table_node.set_attribute('data-table-fields', field_data.to_json)
        table_node.set_attribute('data-table-filter', 'true') if json['filter']
        table_node.set_attribute('data-table-markdown', 'true') if json['markdown']

        if json['caption'].present?
          html = Banzai::Filter::MarkdownFilter.new(json['caption'], table_context).call
          caption_node = doc.document.create_element('caption')
          caption_node << html
          table_node.prepend_child(caption_node)
        end

        # frontend needs a wrapper div
        wrapper = doc.document.create_element('div')
        wrapper.add_child(table_node)

        code_node.parent.replace(wrapper)
      end

      def table_header
        labels = fields ? fields.pluck('label') : items.first.keys

        <<~TABLE_HEADER
          | #{labels.join(' | ')} |
          #{'| --- ' * labels.size} |
        TABLE_HEADER
      end

      def table_body
        body = +''
        item_keys = fields ? fields.pluck('key') : items.first.keys

        items.each do |item|
          row = item_keys.map { |key| item[key] || ' ' }

          body << "| #{row.join(' | ')} |\n"
        end

        body
      end

      def field_data
        return fields if fields

        array = []
        items.first.each_key { |value| array.push({ 'key' => value }) }

        array
      end
    end
  end
end
