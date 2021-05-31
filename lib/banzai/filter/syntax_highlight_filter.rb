# frozen_string_literal: true

require 'rouge/plugins/common_mark'
require "asciidoctor/extensions/asciidoctor_kroki/extension"

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML Filter to highlight fenced code blocks
    #
    class SyntaxHighlightFilter < HTML::Pipeline::Filter
      include OutputSafety

      PARAMS_DELIMITER = ':'
      LANG_PARAMS_ATTR = 'data-lang-params'

      CSS   = 'pre:not([data-math-style]):not([data-mermaid-style]):not([data-kroki-style]) > code'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |node|
          highlight_node(node)
        end

        doc
      end

      def highlight_node(node)
        css_classes = +'code highlight js-syntax-highlight'
        lang, lang_params = parse_lang_params(node.attr('lang'))
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
          css_classes << " language-#{language}" if language
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

        highlighted = %(<pre class="#{css_classes}"
                             lang="#{language}"
                             #{lang_params}
                             v-pre="true"><code>#{code}</code></pre>)

        # Extracted to a method to measure it
        replace_parent_pre_element(node, highlighted)
      end

      private

      def parse_lang_params(language)
        return unless language

        lang, params = language.split(PARAMS_DELIMITER, 2)
        formatted_params = %(#{LANG_PARAMS_ATTR}="#{escape_once(params)}") if params

        [lang, formatted_params]
      end

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
        (%w(math suggestion) + ::AsciidoctorExtensions::Kroki::SUPPORTED_DIAGRAM_NAMES).exclude?(language)
      end
    end
  end
end
