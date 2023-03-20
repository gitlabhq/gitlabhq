# frozen_string_literal: true

# Service class to correctly initialize Gitlab::Blame and Kaminari pagination
# objects
module Projects
  class BlameService
    PER_PAGE = 1000
    STREAMING_FIRST_PAGE_SIZE = 200
    STREAMING_PER_PAGE = 2000

    def initialize(blob, commit, params)
      @blob = blob
      @commit = commit
      @streaming_enabled = streaming_state(params)
      @pagination_enabled = pagination_state(params)
      @page = extract_page(params)
      @params = params
    end

    attr_reader :page, :streaming_enabled

    def blame
      Gitlab::Blame.new(blob, commit, range: blame_range)
    end

    def pagination
      return unless pagination_enabled

      Kaminari.paginate_array([], total_count: blob_lines_count, limit: per_page)
        .tap { |pagination| pagination.max_paginates_per(per_page) }
        .page(page)
    end

    def per_page
      streaming_enabled ? STREAMING_PER_PAGE : PER_PAGE
    end

    def total_pages
      total = (blob_lines_count.to_f / per_page).ceil
      return total unless streaming_enabled

      ([blob_lines_count - STREAMING_FIRST_PAGE_SIZE, 0].max.to_f / per_page).ceil + 1
    end

    def total_extra_pages
      [total_pages - 1, 0].max
    end

    def streaming_possible
      Feature.enabled?(:blame_page_streaming, commit.project)
    end

    private

    attr_reader :blob, :commit, :pagination_enabled

    def blame_range
      return unless pagination_enabled || streaming_enabled

      first_line = (page - 1) * per_page + 1

      if streaming_enabled
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

    def streaming_state(params)
      return false unless streaming_possible

      Gitlab::Utils.to_boolean(params[:streaming], default: false)
    end

    def pagination_state(params)
      return false if Gitlab::Utils.to_boolean(params[:no_pagination], default: false)

      Feature.enabled?(:blame_page_pagination, commit.project)
    end

    def overlimit?(page)
      page > total_pages
    end

    def blob_lines_count
      @blob_lines_count ||= blob.data.lines.count
    end
  end
end
