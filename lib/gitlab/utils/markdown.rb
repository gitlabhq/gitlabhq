# frozen_string_literal: true

module Gitlab
  module Utils
    module Markdown
      PUNCTUATION_REGEXP = /[^\p{Word}\- ]/u

      def string_to_anchor(string)
        string
          .strip
          .downcase
          .gsub(PUNCTUATION_REGEXP, '') # remove punctuation
          .tr(' ', '-') # replace spaces with dash
          .squeeze('-') # replace multiple dashes with one
          .gsub(/\A(\d+)\z/, 'anchor-\1') # digits-only hrefs conflict with issue refs
      end
    end
  end
end
