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
      LANG_ATTR = 'data-canonical-lang'
      LANG_PARAMS_ATTR = 'data-lang-params'

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

        lang, lang_params = parse_lang_params(code_node)
        pre_node = code_node.parent

        if lang.present?
          code_node.remove_attribute('lang')
          pre_node.remove_attribute('lang')
        end

        pre_node.set_attribute(LANG_ATTR, escape_once(lang)) if lang.present?
        pre_node.set_attribute(LANG_PARAMS_ATTR, escape_once(lang_params)) if lang_params.present?

        # cmark-gfm added this, it's now in data-lang-params
        pre_node.remove_attribute('data-meta')
        code_node.remove_attribute('data-meta')
      end

      private

      # cmark-gfm's FULL_INFO_STRING render option works with the space delimiter.
      # Which means the language specified on a code block is parsed with spaces. Anything
      # after the first space is placed in the `data-meta` attribute.
      # However GitLab recognizes `:` as an additional delimiter on the lang attribute.
      # So parse out the extra parameter.
      #
      # Original
      # "```suggestion:+1-10 more```" -> '<pre data-canonical-lang="suggestion:+1-10" data-lang-params="more">'.
      #
      # With extra parsing
      # "```suggestion:+1-10 more```" -> '<pre data-canonical-lang="suggestion" data-lang-params="+1-10 more">'.
      def parse_lang_params(code_node)
        pre_node = code_node.parent
        language = pre_node.attr('lang') || code_node.attr('lang')

        return unless language

        language, language_params = language.split(LANG_PARAMS_DELIMITER, 2)

        # cmark-gfm places extra lang parameters into data-meta
        language_params = [pre_node.attr('data-meta'), code_node.attr('data-meta'), language_params].compact.join(' ')

        [language, language_params]
      end
    end
  end
end
