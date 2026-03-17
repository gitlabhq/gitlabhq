# frozen_string_literal: true

module Banzai
  module Filter
    # Prepares a `json:table` if it's been tagged as supporting markdown
    #
    # If the `markdown` option is not specfied or a boolean true, then we do
    # nothing and allow the frontend to sanitize it and display it.
    #
    # If `"markdown": true` is included in the table, we:
    #
    # - Parse and normalise the input
    # - Build the table, running Markdown-specific fields through MarkdownFilter
    # - Add the table options as `data-` attributes for the frontend
    #
    # Note that this filter is run _before_ SanitizationFilter, which means
    # the resulting HTML will be sanitised as if it were directly input by the user.
    # As a corollary, data-table-{fields,filter,markdown} aren't trustable by the
    # frontend.
    class JsonTableFilter < HTML::Pipeline::Filter
      include Concerns::OutputSafety

      CSS   = '[data-canonical-lang="json"][data-lang-params~="table"] > code:only-child'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |node|
          process_json_table(node)
        end

        doc
      end

      private

      def process_json_table(code_node)
        return if code_node.parent&.parent.nil?

        input = Input.parse(code_node.text)
        return unless input

        markdown_context = context.merge(no_sourcepos: true)

        table = doc.document.create_element('table')
        table['data-table-fields'] = input.fields.to_json
        table['data-table-filter'] = 'true' if input.filter
        table['data-table-markdown'] = 'true'

        if input.caption.present?
          caption = doc.document.create_element('caption')
          table << caption
          caption.inner_html = Banzai::Filter::MarkdownFilter.new(input.caption.to_s, markdown_context).call
        end

        table << render_thead(input.fields)
        table << render_tbody(input.fields, input.items, markdown_context)

        wrapper = doc.document.create_element('div')
        wrapper << table

        code_node.parent.replace(wrapper)
      end

      def render_thead(fields)
        thead = doc.document.create_element('thead')

        thead_tr = doc.document.create_element('tr')
        thead << thead_tr
        fields.each do |field|
          th = doc.document.create_element('th')
          thead_tr << th
          # Fields do not support Markdown.
          th.content = field['label'] || field['key']
        end

        thead
      end

      def render_tbody(fields, items, markdown_context)
        tbody = doc.document.create_element('tbody')
        items.each do |item|
          tr = doc.document.create_element('tr')
          tbody << tr
          fields.each do |field|
            td = doc.document.create_element('td')
            tr << td

            cell_markdown = item[field['key']].to_s
            td.inner_html = Banzai::Filter::MarkdownFilter.new(cell_markdown, markdown_context).call

            # If this produced a single <p>, promote the paragraph contents to
            # being the direct cell contents.
            td.child.replace(td.child.children) if td.children.length == 1 && td.child.name == 'p'
          end
        end

        tbody
      end

      class Input
        def self.parse(source)
          json = begin
            Gitlab::Json.safe_parse(source)
          rescue JSON::ParserError
            nil
          end

          return unless json
          return unless json.is_a?(Hash)
          return unless json['markdown']

          begin
            new(json)
          rescue ArgumentError
            nil
          end
        end

        attr_reader :fields, :items, :markdown, :filter, :caption

        def initialize(data)
          self.fields = data['fields']
          self.items = data['items']
          self.markdown = data['markdown']
          self.filter = data['filter']
          self.caption = data['caption']

          raise ArgumentError if fields && !(fields.is_a?(Array) && fields.all?(Hash))
          raise ArgumentError unless items.is_a?(Array) && items.any? && items.all?(Hash)

          # If 'fields' is specified, it has this shape:
          #
          # [
          #   {
          #     "key": "starts_at",
          #     "label": "Date < & >",
          #     "sortable": true
          #   },
          #   {
          #     "key": "url",
          #     "label": "URL"
          #   }
          # ]
          #
          # If not, we infer it based on the keys of the first item only.
          self.fields ||= items.first.keys.map { |key| { 'key' => key } }
        end

        private

        attr_writer :fields, :items, :markdown, :filter, :caption
      end
    end
  end
end
