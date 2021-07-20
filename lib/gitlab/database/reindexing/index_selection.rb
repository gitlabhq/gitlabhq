# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class IndexSelection
        include Enumerable

        # Only reindex indexes with a relative bloat level (bloat estimate / size) higher than this
        MINIMUM_RELATIVE_BLOAT = 0.2

        # Only consider indexes with a total ondisk size in this range (before reindexing)
        INDEX_SIZE_RANGE = (1.gigabyte..100.gigabyte).freeze

        delegate :each, to: :indexes

        def initialize(candidates)
          @candidates = candidates
        end

        private

        attr_reader :candidates

        def indexes
          # This is an explicit N+1 query:
          # Bloat estimates are generally available through a view
          # for all indexes. However, estimating bloat for all
          # indexes at once is an expensive operation. Therefore,
          # we force a N+1 pattern here and estimate bloat on a per-index
          # basis.

          @indexes ||= candidates
            .not_recently_reindexed
            .where(ondisk_size_bytes: INDEX_SIZE_RANGE)
            .sort_by(&:relative_bloat_level) # forced N+1
            .reverse
            .select { |candidate| candidate.relative_bloat_level >= MINIMUM_RELATIVE_BLOAT }
        end
      end
    end
  end
end
