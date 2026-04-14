# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class MergeRequestDiffStream < MergeRequestDiffBase
        include PaginatedDiffs

        def initialize(merge_request_diff, diff_options:)
          # We delete the `offset_index` from `diff_options` since we only
          # need it here and we don't want it to be included in the cache
          # key used for highlight cache.
          offset = diff_options.delete(:offset_index)

          super

          @paginated_collection = load_paginated_collection(offset)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord -- No need to abstract
        def load_paginated_collection(offset)
          relation.offset(offset.to_i)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
