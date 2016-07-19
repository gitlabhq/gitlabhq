require 'rouge/plugins/redcarpet'

module Banzai
  module Filter
    # HTML Filter to highlight fenced code blocks
    #
    class SyntaxHighlightFilter < HTML::Pipeline::Filter
      include Rouge::Plugins::Redcarpet

      def call
        doc.search('pre > code').each do |node|
          highlight_node(node)
        end

        doc
      end

      def highlight_node(node)
        language = node.attr('class')
        code     = node.text

        css_classes = "code highlight"

        lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText
        formatter = Rouge::Formatters::HTML.new

        begin
          code = formatter.format(lexer.lex(code))

          css_classes << " js-syntax-highlight #{lexer.tag}"
        rescue
          # Gracefully handle syntax highlighter bugs/errors to ensure
          # users can still access an issue/comment/etc.
        end

        highlighted = %(<pre class="#{css_classes}"><code>#{code}</code></pre>)

        # Extracted to a method to measure it
        replace_parent_pre_element(node, highlighted)
      end

      private

      def replace_parent_pre_element(node, highlighted)
        # Replace the parent `pre` element with the entire highlighted block
        node.parent.replace(highlighted)
      end

      # Override Rouge::Plugins::Redcarpet#rouge_formatter
      def rouge_formatter(lexer)
        Rouge::Formatters::HTML.new
      end
    end
  end
end
