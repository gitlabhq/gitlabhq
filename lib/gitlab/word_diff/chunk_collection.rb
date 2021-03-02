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
    end
  end
end
