# frozen_string_literal: true

module Gitlab
  module Git
    class BlamePagination
      include Gitlab::Utils::StrongMemoize

      PAGINATION_PER_PAGE = 1000
      STREAMING_FIRST_PAGE_SIZE = 200
      STREAMING_PER_PAGE = 2000

      def initialize(blob, blame_mode, params)
        @blob = blob
        @blame_mode = blame_mode
        @params = params
      end

      def page
        page = params.fetch(:page, 1).to_i

        return 1 if page < 1

        page
      end
      strong_memoize_attr :page

      def per_page
        blame_mode.streaming? ? STREAMING_PER_PAGE : PAGINATION_PER_PAGE
      end
      strong_memoize_attr :per_page

      def total_pages
        total = (blob_lines_count.to_f / per_page).ceil
        return total unless blame_mode.streaming?

        ([blob_lines_count - STREAMING_FIRST_PAGE_SIZE, 0].max.to_f / per_page).ceil + 1
      end
      strong_memoize_attr :total_pages

      def total_extra_pages
        [total_pages - 1, 0].max
      end
      strong_memoize_attr :total_extra_pages

      def paginator
        return if blame_mode.streaming? || blame_mode.full?

        Kaminari.paginate_array([], total_count: blob_lines_count, limit: per_page)
          .tap { |pagination| pagination.max_paginates_per(per_page) }
          .page(page)
      end

      def blame_range
        return if blame_mode.full?

        first_line = ((page - 1) * per_page) + 1

        if blame_mode.streaming?
          return 1..STREAMING_FIRST_PAGE_SIZE if page == 1

          first_line = STREAMING_FIRST_PAGE_SIZE + ((page - 2) * per_page) + 1
        end

        last_line = (first_line + per_page).to_i - 1

        first_line..last_line
      end

      private

      attr_reader :blob, :blame_mode, :params

      def blob_lines_count
        @blob_lines_count ||= blob.data.lines.count
      end
    end
  end
end
