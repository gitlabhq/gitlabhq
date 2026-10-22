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
      LANGUAGE_CLASS_PREFIX = 'language-'

      CSS   = 'pre > code:only-child'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      BARE_PRE_CSS   = 'pre[lang]:not(:has(code))'
      BARE_PRE_XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(BARE_PRE_CSS).freeze

      def call
        wrap_bare_pre_content

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

      # Some markup languages (e.g., org-ruby) produce <pre lang="ruby">code</pre>
      # without a <code> wrapper. Wrap these so pre > code:only-child can match.
      def wrap_bare_pre_content
        doc.xpath(BARE_PRE_XPATH).each do |pre_node|
          code_node = Nokogiri::XML::Node.new('code', doc)
          code_node.children = pre_node.children
          pre_node.add_child(code_node)
        end
      end

      def extract_language_with_priority(code_node, pre_node)
        # Priority: data-lang > CSS class > legacy lang attribute
        pre_node.attr('data-lang') ||
          code_node.attr('data-lang') ||
          extract_language_from_class(code_node) ||
          pre_node.attr('lang') ||
          code_node.attr('lang')
      end

      # Returns [language_class, other_classes] from a code node's class attribute.
      # language_class is the first `language-*` token found (nil if none).
      def partition_language_class(code_node)
        classes = code_node.attr('class')&.split
        return [nil, nil] unless classes

        language_class, others = classes.partition { |c| c.start_with?(LANGUAGE_CLASS_PREFIX) }
        [language_class.first, others]
      end

      def extract_language_from_class(code_node)
        lang_class, = partition_language_class(code_node)
        lang_class&.delete_prefix(LANGUAGE_CLASS_PREFIX)
      end

      def remove_language_class(code_node)
        lang_class, others = partition_language_class(code_node)
        return unless lang_class

        if others.empty?
          code_node.remove_attribute('class')
        else
          code_node.set_attribute('class', others.join(' '))
        end
      end

      def cleanup_all_language_attributes(code_node, pre_node)
        code_node.remove_attribute('lang')
        code_node.remove_attribute('data-lang')
        pre_node.remove_attribute('lang')
        pre_node.remove_attribute('data-meta')
        code_node.remove_attribute('data-meta')
        remove_language_class(code_node)
      end

      def set_final_language_attributes(pre_node, lang, lang_params)
        pre_node.set_attribute('data-lang', lang)
        pre_node.set_attribute('data-canonical-lang', lang)
        pre_node.set_attribute('data-lang-params', lang_params) if lang_params
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
