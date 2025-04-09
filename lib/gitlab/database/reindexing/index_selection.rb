# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class IndexSelection
        include Enumerable

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
            .select { |candidate| candidate.relative_bloat_level >= minimum_relative_bloat_size }
        end

        def relations_that_need_cleaning_before_deadline
          relation = candidates.not_recently_reindexed.where('ondisk_size_bytes >= ?', minimum_index_size)
          relation = relation.where.not(tablename: VERY_LARGE_TABLES) if too_late_for_very_large_table?
          relation
        end

        def minimum_index_size
          Gitlab::CurrentSettings.reindexing_minimum_index_size
        end

        def minimum_relative_bloat_size
          Gitlab::CurrentSettings.reindexing_minimum_relative_bloat_size
        end

        # The reindexing process takes place during the weekends and starting a
        # reindexing action on a large table late on Sunday could span during
        # Monday. We don't want this because it prevents vacuum from running.
        def too_late_for_very_large_table?
          return false unless Gitlab.com_except_jh? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Not related to SaaS offerings

          !Date.today.saturday?
        end
      end
    end
  end
end
