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
      # replaces the ^ used in kramdown.  This forces the current
      # block to end, so that a different list or codeblock can be
      # started. https://kramdown.gettalong.org/syntax.html#eob-marker
      END_OF_BLOCK = '<!-- -->'

      def convert(el, opts = { indent: 0 })
        res = super

        if [:ul, :dl, :ol, :codeblock].include?(el.type) && opts[:next] &&
            ([el.type, :codeblock].include?(opts[:next].type) ||
              (opts[:next].type == :blank && opts[:nnext] &&
                [el.type, :codeblock].include?(opts[:nnext].type)))
          # replace the end of block character
          res.sub!(/\^\n\n\z/m, "#{END_OF_BLOCK}\n\n")
        end

        res
      end

      def convert_codeblock(el, _opts)
        # Although tildes are supported in CommonMark, backticks are more common
        "```#{el.options[:lang]}\n" +
          el.value.split("\n").map { |l| l.empty? ? "" : l.to_s }.join("\n") +
          "\n```\n\n"
      end

      def convert_li(el, opts)
        res = super

        if el.children.first && el.children.first.type == :p && !el.children.first.options[:transparent]
          if el.children.size == 1 && @stack.last.children.last == el &&
              (@stack.last.children.any? { |c| c.children.first.type != :p } || @stack.last.children.size == 1)
            # replace the end of block character
            res.sub!(/\^\n\z/m, "#{END_OF_BLOCK}\n")
          end
        end

        res
      end

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

        "<tr>\n#{el.children.map { |c| convert(c, opts) }.join}</tr>\n"
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
