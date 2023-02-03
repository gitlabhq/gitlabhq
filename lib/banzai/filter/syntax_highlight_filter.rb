# frozen_string_literal: true

require 'rouge/plugins/common_mark'
require 'asciidoctor/extensions/asciidoctor_kroki/version'
require 'asciidoctor/extensions/asciidoctor_kroki/extension'

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML Filter to highlight fenced code blocks
    #
    class SyntaxHighlightFilter < TimeoutHtmlPipelineFilter
      include OutputSafety

      LANG_PARAMS_DELIMITER = ':'
      LANG_PARAMS_ATTR = 'data-lang-params'
      CSS_CLASSES = 'code highlight js-syntax-highlight'

      CSS   = 'pre:not([data-kroki-style]) > code:only-child'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call_with_timeout
        doc.xpath(XPATH).each do |node|
          highlight_node(node)
        end

        doc
      end

      def highlight_node(node)
        return if node.parent&.parent.nil?

        lang, lang_params = parse_lang_params(node)
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

        # maintain existing attributes already added. e.g math and mermaid nodes
        node.children = code
        pre_node = node.parent

        # ensure there are no extra children, such as a text node that might
        # show up from an XSS attack
        pre_node.children = node

        pre_node[:lang] = language
        pre_node.add_class(CSS_CLASSES)
        pre_node.add_class("language-#{language}") if language
        pre_node.set_attribute('data-canonical-lang', escape_once(lang)) if lang != language
        pre_node.set_attribute(LANG_PARAMS_ATTR, escape_once(lang_params)) if lang_params.present?
        pre_node.set_attribute('v-pre', 'true')
        pre_node.remove_attribute('data-meta')
        copy_code_btn = "<copy-code></copy-code>" unless language == 'suggestion'

        highlighted = %(<div class="gl-relative markdown-code-block js-markdown-code">#{pre_node.to_html}#{copy_code_btn}</div>)

        # Extracted to a method to measure it
        replace_pre_element(pre_node, highlighted)
      end

      private

      def parse_lang_params(node)
        node = node.parent

        # Commonmarker's FULL_INFO_STRING render option works with the space delimiter.
        # But the current behavior of GitLab's markdown renderer is different - it grabs everything as the single
        # line, including language and its options. To keep backward compatibility, we have to parse the old format and
        # merge with the new one.
        #
        # Behaviors before separating language and its parameters:
        # Old ones:
        # "```ruby with options```" -> '<pre><code lang="ruby with options">'.
        # "```ruby:with:options```" -> '<pre><code lang="ruby:with:options">'.
        #
        # New ones:
        # "```ruby with options```" -> '<pre><code lang="ruby" data-meta="with options">'.
        # "```ruby:with:options```" -> '<pre><code lang="ruby:with:options">'.

        language = node.attr('lang')

        return unless language

        language, language_params = language.split(LANG_PARAMS_DELIMITER, 2)
        language_params = [node.attr('data-meta'), language_params].compact.join(' ')

        [language, language_params]
      end

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
        (%w(math suggestion) + ::AsciidoctorExtensions::Kroki::SUPPORTED_DIAGRAM_NAMES).exclude?(language)
      end
    end
  end
end
