# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class IndexSelection
        include Enumerable

        # Only reindex indexes with a relative bloat level (bloat estimate / size) higher than this
        MINIMUM_RELATIVE_BLOAT = 0.2

        # Only consider indexes beyond this size (before reindexing)
        INDEX_SIZE_MINIMUM = 1.gigabyte

        VERY_LARGE_TABLES = %i[
          ci_builds
        ].freeze

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

          @indexes ||= relations_that_need_cleaning_before_deadline
            .sort_by(&:relative_bloat_level) # forced N+1
            .reverse
            .select { |candidate| candidate.relative_bloat_level >= MINIMUM_RELATIVE_BLOAT }
        end

        def relations_that_need_cleaning_before_deadline
          relation = candidates.not_recently_reindexed.where('ondisk_size_bytes >= ?', INDEX_SIZE_MINIMUM)
          relation = relation.where.not(tablename: VERY_LARGE_TABLES) if too_late_for_very_large_table?
          relation
        end

        # The reindexing process takes place during the weekends and starting a
        # reindexing action on a large table late on Sunday could span during
        # Monday. We don't want this because it prevents vacuum from running.
        def too_late_for_very_large_table?
          !Date.today.saturday?
        end
      end
    end
  end
end
