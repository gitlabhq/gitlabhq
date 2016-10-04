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
        code = node.text
        css_classes = "code highlight"
        lexer = lexer_for(language)

        begin
          code = format(lex(lexer, code))

          css_classes << " js-syntax-highlight #{lexer.tag}"
        rescue
          # Gracefully handle syntax highlighter bugs/errors to ensure
          # users can still access an issue/comment/etc.
        end

        highlighted = %(<pre class="#{css_classes}" v-pre="true"><code>#{code}</code></pre>)

        # Extracted to a method to measure it
        replace_parent_pre_element(node, highlighted)
      end

      private

      # Separate method so it can be instrumented.
      def lex(lexer, code)
        lexer.lex(code)
      end

      def format(tokens)
        rouge_formatter.format(tokens)
      end

      def lexer_for(language)
        (Rouge::Lexer.find(language) || Rouge::Lexers::PlainText).new
      end

      def replace_parent_pre_element(node, highlighted)
        # Replace the parent `pre` element with the entire highlighted block
        node.parent.replace(highlighted)
      end

      # Override Rouge::Plugins::Redcarpet#rouge_formatter
      def rouge_formatter(lexer = nil)
        @rouge_formatter ||= Rouge::Formatters::HTML.new
      end
    end
  end
end
