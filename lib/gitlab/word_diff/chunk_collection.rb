# frozen_string_literal: true

module Gitlab
  module WordDiff
    class ChunkCollection
      def initialize
        @chunks = []
      end

      def add(chunk)
        @chunks << chunk
      end

      def content
        @chunks.join('')
      end

      def reset
        @chunks = []
      end

      def marker_ranges
        start = 0

        @chunks.each_with_object([]) do |element, ranges|
          mode = mode_for_element(element)

          ranges << Gitlab::MarkerRange.new(start, start + element.length - 1, mode: mode) if mode

          start += element.length
        end
      end

      private

      def mode_for_element(element)
        return Gitlab::MarkerRange::DELETION if element.removed?
        return Gitlab::MarkerRange::ADDITION if element.added?

        nil
      end
    end
  end
end
