# frozen_string_literal: true

# Service class to correctly initialize Gitlab::Blame and Kaminari pagination
# objects
module Projects
  class BlameService
    PER_PAGE = 1000
    STREAMING_FIRST_PAGE_SIZE = 200
    STREAMING_PER_PAGE = 2000

    def initialize(blob, commit, blame_mode, params)
      @blob = blob
      @commit = commit
      @blame_mode = blame_mode
      @page = extract_page(params)
      @params = params
    end

    attr_reader :page

    def blame
      Gitlab::Blame.new(blob, commit, range: blame_range)
    end

    def pagination
      return unless blame_mode.pagination?

      Kaminari.paginate_array([], total_count: blob_lines_count, limit: per_page)
        .tap { |pagination| pagination.max_paginates_per(per_page) }
        .page(page)
    end

    def per_page
      blame_mode.streaming? ? STREAMING_PER_PAGE : PER_PAGE
    end

    def total_pages
      total = (blob_lines_count.to_f / per_page).ceil
      return total unless blame_mode.streaming?

      ([blob_lines_count - STREAMING_FIRST_PAGE_SIZE, 0].max.to_f / per_page).ceil + 1
    end

    def total_extra_pages
      [total_pages - 1, 0].max
    end

    private

    attr_reader :blob, :commit, :blame_mode

    def blame_range
      return if blame_mode.full?

      first_line = (page - 1) * per_page + 1

      if blame_mode.streaming?
        return 1..STREAMING_FIRST_PAGE_SIZE if page == 1

        first_line = STREAMING_FIRST_PAGE_SIZE + (page - 2) * per_page + 1
      end

      last_line = (first_line + per_page).to_i - 1

      first_line..last_line
    end

    def extract_page(params)
      page = params.fetch(:page, 1).to_i

      return 1 if page < 1 || overlimit?(page)

      page
    end

    def overlimit?(page)
      page > total_pages
    end

    def blob_lines_count
      @blob_lines_count ||= blob.data.lines.count
    end
  end
end
