# frozen_string_literal: true

require 'rouge/plugins/common_mark'
require 'asciidoctor/extensions/asciidoctor_kroki/version'
require 'asciidoctor/extensions/asciidoctor_kroki/extension'

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML Filter to highlight fenced code blocks
    #
    class SyntaxHighlightFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler
      prepend Concerns::PipelineTimingCheck
      include Concerns::OutputSafety

      CSS_CLASSES = 'code highlight js-syntax-highlight'

      CSS   = 'pre:not([data-kroki-style]) > code:only-child'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |node|
          highlight_node(node)
        end

        doc
      end

      def highlight_node(code_node)
        return if code_node.parent&.parent.nil?

        # maintain existing attributes already added. e.g math and mermaid nodes
        pre_node = code_node.parent

        lang = pre_node['data-canonical-lang']
        retried = false

        if use_rouge?(lang)
          lexer = lexer_for(lang)
          language = lexer.tag
        else
          lexer = Rouge::Lexers::PlainText.new
          language = lang
        end

        begin
          code = Rouge::Formatters::HTMLGitlab.format(lex(lexer, code_node.text), tag: language)
        rescue StandardError
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

        code_node.children = code

        # ensure there are no extra children, such as a text node that might
        # show up from an XSS attack
        pre_node.children = code_node

        pre_node.add_class(CSS_CLASSES)
        pre_node.add_class("language-#{language}") if language
        pre_node.set_attribute('v-pre', 'true')
        copy_code_btn = "<copy-code></copy-code>" unless language == 'suggestion'
        insert_code_snippet_btn = "<insert-code-snippet></insert-code-snippet>" unless language == 'suggestion'

        highlighted = %(<div class="gl-relative markdown-code-block js-markdown-code">#{pre_node.to_html}#{copy_code_btn}#{insert_code_snippet_btn}</div>)

        # Extracted to a method to measure it
        replace_pre_element(pre_node, highlighted)
      end

      private

      # Separate method so it can be instrumented.
      def lex(lexer, code)
        lexer.lex(code)
      end

      def lexer_for(language)
        (Rouge::Lexer.find(language) || Rouge::Lexers::PlainText).new
      end

      # Replace the `pre` element with the entire highlighted block
      def replace_pre_element(pre_node, highlighted)
        pre_node.replace(highlighted)
      end

      def use_rouge?(language)
        (%w[math suggestion] + ::AsciidoctorExtensions::Kroki::SUPPORTED_DIAGRAM_NAMES).exclude?(language)
      end
    end
  end
end
