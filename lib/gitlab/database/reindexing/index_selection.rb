# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class IndexSelection
        include Enumerable

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

          @indexes ||= filter_candidates.sort_by(&:bloat_size).reverse
        end

        def filter_candidates
          candidates.not_recently_reindexed
        end
      end
    end
  end
end
