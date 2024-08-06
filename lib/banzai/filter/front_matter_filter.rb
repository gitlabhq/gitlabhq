# frozen_string_literal: true

module Banzai
  module Filter
    class FrontMatterFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def call
        lang_mapping = Gitlab::FrontMatter::DELIM_LANG

        Gitlab::FrontMatter::PATTERN_UNTRUSTED_REGEX
          .replace_gsub(html, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match|
          lang = match[:lang].presence || lang_mapping[match[:delim]]

          before = match[:before]
          before = "\n#{before}" if match[:encoding].presence

          "#{before}```#{lang}:frontmatter\n#{match[:front_matter]}```\n"
        end
      end
    end
  end
end
