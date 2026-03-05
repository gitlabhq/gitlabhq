# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter to convert use of `lang` attribute into a common format,
    # data-canonical-lang, as the `lang` attribute is really meant for accessibility
    # and not for specifying code highlight language.
    # See https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang#accessibility
    # This also provides one place to transform the language specification format, whether it
    # sits on the `pre` or `code`, or in a `class` or `lang` attribute
    class CodeLanguageFilter < HTML::Pipeline::Filter
      include Concerns::OutputSafety
      prepend Concerns::PipelineTimingCheck

      LANG_PARAMS_DELIMITER = ':'

      CSS   = 'pre > code:only-child'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |node|
          transform_node(node)
        end

        doc
      end

      def transform_node(code_node)
        return if code_node.parent&.parent.nil?

        pre_node = code_node.parent

        # Single-pass language extraction with clear priority
        language = extract_language_with_priority(code_node, pre_node)

        # Handle data-meta parameters
        meta_params = pre_node.attr('data-meta') || code_node.attr('data-meta')

        lang, lang_params = parse_language_params(language)

        # Use meta_params if no lang_params from language string
        lang_params = meta_params if lang_params.blank? && meta_params.present?

        # Clean up ALL temporary attributes once
        cleanup_all_language_attributes(code_node, pre_node)

        # Set final canonical attributes once
        set_final_language_attributes(pre_node, lang, lang_params) if lang.present?
      end

      private

      def extract_language_with_priority(code_node, pre_node)
        pre_node.attr('lang') || code_node.attr('lang')
      end

      def cleanup_all_language_attributes(code_node, pre_node)
        code_node.remove_attribute('lang')
        pre_node.remove_attribute('lang')
        pre_node.remove_attribute('data-meta')
        code_node.remove_attribute('data-meta')
      end

      def set_final_language_attributes(pre_node, lang, lang_params)
        pre_node.set_attribute('data-canonical-lang', escape_once(lang))
        pre_node.set_attribute('data-lang-params', escape_once(lang_params)) if lang_params
      end

      # Parses language parameters from a language string.
      # Examples:
      #   "ruby" -> ["ruby", nil]
      #   "ruby:red" -> ["ruby", "red"]
      #   "suggestion:+1-10 more" -> ["suggestion", "+1-10 more"]
      def parse_language_params(language_string)
        return [nil, nil] unless language_string

        # Handle "ruby:red gem foo" -> ["ruby", "red gem foo"]
        lang, params = language_string.split(LANG_PARAMS_DELIMITER, 2)
        params = params&.strip&.presence

        [lang, params]
      end
    end
  end
end
