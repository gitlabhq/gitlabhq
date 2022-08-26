# frozen_string_literal: true

module Banzai
  module Filter
    class PathologicalMarkdownFilter < HTML::Pipeline::TextFilter
      # It's not necessary for this to be precise - we just need to detect
      # when there are a non-trivial number of unclosed image links.
      # So we don't really care about code blocks, etc.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/370428
      REGEX = /!\[(?:[^\]])+?!\[/.freeze
      DETECTION_MAX = 10

      def call
        count = 0

        @text.scan(REGEX) do |_match|
          count += 1
          break if count > DETECTION_MAX
        end

        return @text if count <= DETECTION_MAX

        "_Unable to render markdown - too many unclosed markdown image links detected._"
      end
    end
  end
end
