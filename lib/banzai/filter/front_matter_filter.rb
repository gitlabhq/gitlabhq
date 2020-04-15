# frozen_string_literal: true

module Banzai
  module Filter
    class FrontMatterFilter < HTML::Pipeline::Filter
      def call
        lang_mapping = Gitlab::FrontMatter::DELIM_LANG

        html.sub(Gitlab::FrontMatter::PATTERN) do |_match|
          lang = $~[:lang].presence || lang_mapping[$~[:delim]]

          ["```#{lang}", $~[:front_matter], "```", "\n"].join("\n")
        end
      end
    end
  end
end
