# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class MergeRequestDiffStream < MergeRequestDiffBase
        include PaginatedDiffs

        def initialize(merge_request_diff, diff_options:)
          super

          @paginated_collection = load_paginated_collection(diff_options)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord -- No need to abstract
        def load_paginated_collection(diff_options)
          relation.offset(diff_options[:offset_index].to_i || 0)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
