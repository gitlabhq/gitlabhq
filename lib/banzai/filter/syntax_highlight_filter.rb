require 'rouge/plugins/redcarpet'

module Banzai
  module Filter
    # HTML Filter to highlight fenced code blocks
    #
    class SyntaxHighlightFilter < HTML::Pipeline::Filter
      def call
        doc.search('pre > code').each do |node|
          highlight_node(node)
        end

        doc
      end

      def highlight_node(node)
        language = node.attr('lang')
        code = node.text
        css_classes = "code highlight"
        lexer = lexer_for(language)
        lang = lexer.tag

        begin
          code = Rouge::Formatters::HTMLGitlab.format(lex(lexer, code), tag: lang)

          css_classes << " js-syntax-highlight #{lang}"
        rescue
          lang = nil
          # Gracefully handle syntax highlighter bugs/errors to ensure
          # users can still access an issue/comment/etc.
        end

        highlighted = %(<pre class="#{css_classes}" lang="#{lang}" v-pre="true"><code>#{code}</code></pre>)

        # Extracted to a method to measure it
        replace_parent_pre_element(node, highlighted)
      end

      private

      # Separate method so it can be instrumented.
      def lex(lexer, code)
        lexer.lex(code)
      end

      def lexer_for(language)
        (Rouge::Lexer.find(language) || Rouge::Lexers::PlainText).new
      end

      def replace_parent_pre_element(node, highlighted)
        # Replace the parent `pre` element with the entire highlighted block
        node.parent.replace(highlighted)
      end
    end
  end
end
