# frozen_string_literal: true

module Gitlab
  module Diff
    class PositionCollection
      include Enumerable

      # collection - An array of Gitlab::Diff::Position
      def initialize(collection, diff_head_sha)
        @collection = collection
        @diff_head_sha = diff_head_sha
      end

      def each(&block)
        @collection.each(&block)
      end

      def concat(positions)
        tap { @collection.concat(positions) }
      end

      # Doing a lightweight filter in-memory given we're not prepared for querying
      # positions (https://gitlab.com/gitlab-org/gitlab/issues/33271).
      def unfoldable
        select do |position|
          position.unfoldable? && position.head_sha == @diff_head_sha
        end
      end
    end
  end
end
