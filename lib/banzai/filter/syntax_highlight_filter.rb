require 'rouge/plugins/common_mark'
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
        css_classes = 'code highlight js-syntax-highlight'
        lang = node.attr('lang')
        retried = false

        if use_rouge?(lang)
          lexer = lexer_for(lang)
          language = lexer.tag
        else
          lexer = Rouge::Lexers::PlainText.new
          language = lang
        end

        begin
          code = Rouge::Formatters::HTMLGitlab.format(lex(lexer, node.text), tag: language)
          css_classes << " #{language}" if language
        rescue
          # Gracefully handle syntax highlighter bugs/errors to ensure users can
          # still access an issue/comment/etc. First, retry with the plain text
          # filter. If that fails, then just skip this entirely, but that would
          # be a pretty bad upstream bug.
          return if retried

          language = nil
          lexer = Rouge::Lexers::PlainText.new
          retried = true

          retry
        end

        highlighted = %(<pre class="#{css_classes}" lang="#{language}" v-pre="true"><code>#{code}</code></pre>)

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

      def use_rouge?(language)
        %w(math mermaid plantuml).exclude?(language)
      end
    end
  end
end
