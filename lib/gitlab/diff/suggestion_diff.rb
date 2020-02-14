# frozen_string_literal: true

module Gitlab
  module Diff
    class SuggestionDiff
      include Gitlab::Utils::StrongMemoize

      delegate :from_content, :to_content, :from_line, to: :@suggestible

      def initialize(suggestible)
        @suggestible = suggestible
      end

      def diff_lines
        Gitlab::Diff::Parser.new.parse(raw_diff.each_line).to_a
      end

      private

      def raw_diff
        "#{diff_header}\n#{from_content_as_diff}\n#{to_content_as_diff}"
      end

      def diff_header
        "@@ -#{from_line} +#{from_line}"
      end

      def from_content_as_diff
        from_content.lines.map { |line| line.prepend('-') }.join.delete_suffix("\n")
      end

      def to_content_as_diff
        to_content.lines.map { |line| line.prepend('+') }.join
      end
    end
  end
end
