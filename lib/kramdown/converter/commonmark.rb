# frozen_string_literal: true

module Kramdown
  module Converter
    # Overrides the base Kramdown converter to add any special
    # behaviour for CommonMark.
    #
    # Currently we support an option `html_tables` that outputs
    # an HTML table instead of a Markdown table.  This is to
    # support possibly being given complex tables, such as from ADF.
    #
    # Note: this is only an initial implementation.  Currently don't
    # strip out IALs or other specific kramdown syntax.
    class Commonmark < ::Kramdown::Converter::Kramdown
      def convert_table(el, opts)
        return super unless @options[:html_tables]

        opts[:alignment] = el.options[:alignment]
        result = inner(el, opts)

        "<table>\n#{result}</table>\n\n"
      end

      def convert_thead(el, opts)
        return super unless @options[:html_tables]

        "<thead>\n#{inner(el, opts)}</thead>\n"
      end

      def convert_tbody(el, opts)
        return super unless @options[:html_tables]

        "<tbody>\n#{inner(el, opts)}</tbody>\n"
      end

      def convert_tfoot(el, opts)
        return super unless @options[:html_tables]

        "<tfoot>\n#{inner(el, opts)}</tfoot>\n"
      end

      def convert_tr(el, opts)
        return super unless @options[:html_tables]

        "<tr>\n#{el.children.map {|c| convert(c, opts) }.join}</tr>\n"
      end

      def convert_td(el, opts)
        return super unless @options[:html_tables]

        # We need to add two linefeeds in order for any inner text to
        # be processed as markdown.  The HTML block must be "closed",
        # as referenced in the CommonMark spec
        # @see https://spec.commonmark.org/0.29/#html-blocks
        "<td>\n\n#{inner(el, opts)}</td>\n"
      end

      def convert_th(el, opts)
        return super unless @options[:html_tables]

        # We need to add two linefeeds in order for any inner text to
        # be processed as markdown.  The HTML block must be "closed",
        # as referenced in the CommonMark spec
        # @see https://spec.commonmark.org/0.29/#html-blocks
        "<th>\n\n#{inner(el, opts)}</th>\n"
      end
    end
  end
end
