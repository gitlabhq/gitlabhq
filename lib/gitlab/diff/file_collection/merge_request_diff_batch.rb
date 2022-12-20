# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      # Builds a paginated diff file collection and collects pagination
      # metadata.
      #
      # It doesn't handle caching yet as we're not prepared to write/read
      # separate file keys (https://gitlab.com/gitlab-org/gitlab/issues/30550).
      #
      class MergeRequestDiffBatch < MergeRequestDiffBase
        include PaginatedDiffs

        DEFAULT_BATCH_PAGE = 1
        DEFAULT_BATCH_SIZE = 30

        attr_reader :pagination_data

        def initialize(merge_request_diff, batch_page, batch_size, diff_options:)
          super(merge_request_diff, diff_options: diff_options)

          @paginated_collection = load_paginated_collection(batch_page, batch_size, diff_options)

          @pagination_data = {
            total_pages: @paginated_collection.blank? ? nil : relation.size
          }
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def load_paginated_collection(batch_page, batch_size, diff_options)
          batch_page ||= DEFAULT_BATCH_PAGE
          batch_size ||= DEFAULT_BATCH_SIZE

          paths = diff_options&.fetch(:paths, nil)

          paginated_collection = relation.offset(batch_page).limit([batch_size.to_i, DEFAULT_BATCH_SIZE].min)
          paginated_collection = paginated_collection.by_paths(paths) if paths

          paginated_collection
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
