require 'gitlab/markdown'
require 'html/pipeline/filter'
require 'rouge/plugins/redcarpet'

module Gitlab
  module Markdown
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

        begin
          highlighted = block_code(code, language)
        rescue
          # Gracefully handle syntax highlighter bugs/errors to ensure
          # users can still access an issue/comment/etc.
          highlighted = "<pre>#{code}</pre>"
        end

        # Replace the parent `pre` element with the entire highlighted block
        node.parent.replace(highlighted)
      end

      private

      # Override Rouge::Plugins::Redcarpet#rouge_formatter
      def rouge_formatter(lexer)
        Rouge::Formatters::HTMLGitlab.new(
          cssclass: "code highlight js-syntax-highlight #{lexer.tag}")
      end
    end
  end
end
