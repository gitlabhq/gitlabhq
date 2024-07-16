# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      # Builds a traditional paginated diff file collection using Kaminari
      # `per` and `per_page` which is different from how `MergeRequestDiffBatch`
      # works (e.g. supports gradual loading).
      class PaginatedMergeRequestDiff < MergeRequestDiffBase
        include PaginatedDiffs

        DEFAULT_PAGE = 1
        DEFAULT_PER_PAGE = 30

        delegate :limit_value, :current_page, :next_page, :prev_page, :total_count,
          :total_pages, to: :paginated_collection

        def initialize(merge_request_diff, page, per_page)
          super(merge_request_diff, diff_options: nil)

          @paginated_collection = load_paginated_collection(page, per_page)
        end

        private

        def load_paginated_collection(page, per_page)
          page ||= DEFAULT_PAGE
          per_page ||= DEFAULT_PER_PAGE

          relation.page(page).per([per_page.to_i, DEFAULT_PER_PAGE].min)
        end
      end
    end
  end
end
