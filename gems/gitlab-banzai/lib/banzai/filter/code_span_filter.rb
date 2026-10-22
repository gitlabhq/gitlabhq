# frozen_string_literal: true

module Banzai
  module Filter
    # Finds backtick-enclosed text and nests them into <code>.
    # e.g. an HTML document like "<html><body>Hello, `world`.</body></html>"
    # becomes "<html><body>Hello, <code>world</code>.</body></html>".
    #
    # Also applies a layer of escaping, but only to backticks: e.g.
    # "hello \\`world`" becomes "hello `world`" (no "<code>"), but
    # "hello \\there" remains "hello \\there".
    #
    # This class doesn't do any exclusion on parents: it'll happily insert
    # <code>s into any parent tag. Its current use case matches this, but
    # be sure this is what you want before adding to a new site.
    class CodeSpanFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler

      TEXT_QUERY = 'descendant-or-self::text()'

      TOKEN = /(\\\\)|(\\`)|`([^`]*)`|([^\\`]+)|(.)/

      def call
        doc.xpath(TEXT_QUERY).each do |node|
          r = []
          buf = +""

          node.content.scan(TOKEN) do |(dbs, ebt, code, text, char)|
            if dbs
              buf << dbs
            elsif ebt
              buf << '`'
            elsif code
              r << buf
              buf = +""
              r << code
            elsif text
              buf << text
            elsif char
              buf << char
            end
          end

          r << buf

          # r contains [text, code, text, code ...]; text at even indices, code at odd ones.
          # We use `node.add_next_sibling` repeatedly, so we must insert in reverse order,
          # as the last insertion will be closest to `node`.
          r.each.with_index.reverse_each do |content, i|
            next if content.empty?

            text = i.even?
            node.add_next_sibling(
              text ? doc.document.create_text_node(content) : doc.document.create_element('code', content))
          end

          node.remove
        end

        doc
      end
    end
  end
end
