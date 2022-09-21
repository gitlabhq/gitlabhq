# frozen_string_literal: true

# Service class to correctly initialize Gitlab::Blame and Kaminari pagination
# objects
module Projects
  class BlameService
    PER_PAGE = 1000

    def initialize(blob, commit, params)
      @blob = blob
      @commit = commit
      @page = extract_page(params)
      @pagination_enabled = pagination_state(params)
    end

    attr_reader :page

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
      PER_PAGE
    end

    private

    attr_reader :blob, :commit, :pagination_enabled

    def blame_range
      return unless pagination_enabled

      first_line = (page - 1) * per_page + 1
      last_line = (first_line + per_page).to_i - 1

      first_line..last_line
    end

    def extract_page(params)
      page = params.fetch(:page, 1).to_i

      return 1 if page < 1 || overlimit?(page)

      page
    end

    def pagination_state(params)
      return false if Gitlab::Utils.to_boolean(params[:no_pagination], default: false)

      Feature.enabled?(:blame_page_pagination, commit.project)
    end

    def overlimit?(page)
      page * per_page >= blob_lines_count + per_page
    end

    def blob_lines_count
      @blob_lines_count ||= blob.data.lines.count
    end
  end
end
