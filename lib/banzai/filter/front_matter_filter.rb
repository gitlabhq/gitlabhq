# frozen_string_literal: true

module Banzai
  module Filter
    class FrontMatterFilter < HTML::Pipeline::Filter
      DELIM_LANG = {
        '---' => 'yaml',
        '+++' => 'toml',
        ';;;' => 'json'
      }.freeze

      DELIM = Regexp.union(DELIM_LANG.keys)

      PATTERN = %r{
        \A(?:[^\r\n]*coding:[^\r\n]*)?         # optional encoding line
        \s*
        ^(?<delim>#{DELIM})[ \t]*(?<lang>\S*)  # opening front matter marker (optional language specifier)
        \s*
        ^(?<front_matter>.*?)                  # front matter (not greedy)
        \s*
        ^\k<delim>                             # closing front matter marker
        \s*
      }mx.freeze

      def call
        html.sub(PATTERN) do |_match|
          lang = $~[:lang].presence || DELIM_LANG[$~[:delim]]

          ["```#{lang}", $~[:front_matter], "```", "\n"].join("\n")
        end
      end
    end
  end
end
