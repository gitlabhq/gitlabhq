# frozen_string_literal: true

module Gitlab
  module Diff
    class FileCollectionSorter
      attr_reader :diffs

      def initialize(diffs)
        @diffs = diffs
      end

      def sort
        diffs.sort do |a, b|
          compare_path_parts(path_parts(a), path_parts(b))
        end
      end

      private

      def path_parts(diff)
        (diff.new_path.presence || diff.old_path).split(::File::SEPARATOR)
      end

      # Used for sorting the file paths by:
      # 1. Directory name
      # 2. Depth
      # 3. File name
      def compare_path_parts(a_parts, b_parts)
        a_part = a_parts.shift
        b_part = b_parts.shift

        return 1 if a_parts.size < b_parts.size && a_parts.empty?
        return -1 if a_parts.size > b_parts.size && b_parts.empty?

        comparison = a_part <=> b_part

        return comparison unless comparison == 0

        compare_path_parts(a_parts, b_parts)
      end
    end
  end
end
