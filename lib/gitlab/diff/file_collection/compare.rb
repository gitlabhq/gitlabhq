# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class Compare < Base
        delegate :limit_value, :current_page, :next_page, :prev_page, :total_count, :total_pages, to: :@pagination

        def initialize(compare, project:, diff_options:, diff_refs: nil)
          @pagination = Gitlab::PaginationDelegate.new(
            page: diff_options&.delete(:page),
            per_page: diff_options&.delete(:per_page),
            count: diff_options&.delete(:count)
          )

          super(compare,
            project: project,
            diff_options: diff_options,
            diff_refs: diff_refs)
        end

        def unfold_diff_lines(positions)
          # no-op
        end

        def cache_key
          ['compare', @diffable.head.id, @diffable.base.id]
        end
      end
    end
  end
end
