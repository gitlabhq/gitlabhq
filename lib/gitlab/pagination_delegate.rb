module Gitlab
  class PaginationDelegate
    DEFAULT_PER_PAGE = Kaminari.config.default_per_page
    MAX_PER_PAGE = Kaminari.config.max_per_page

    def initialize(page:, per_page:, count:, options: {})
      @count = count
      @options = { default_per_page: DEFAULT_PER_PAGE,
                   max_per_page: MAX_PER_PAGE }.merge(options)

      @page = sanitize_page(page)
      @per_page = sanitize_per_page(per_page)
    end

    def total_count
      @count
    end

    def total_pages
      (total_count.to_f / @per_page).ceil
    end

    def next_page
      current_page + 1 unless last_page?
    end

    def prev_page
      return nil if first_page?

      current_page - 1 unless first_page?
    end

    def current_page
      @page
    end

    def limit_value
      @per_page
    end

    def first_page?
      current_page == 1
    end

    def last_page?
      current_page >= total_pages
    end

    def offset
      (current_page - 1) * limit_value
    end

    private

    def sanitize_per_page(per_page)
      return @options[:default_per_page] unless per_page && per_page > 0

      per_page > @options[:max_per_page] ? @options[:max_per_page] : per_page
    end

    def sanitize_page(page)
      return 1 unless page && page > 1

      page > total_count ? total_count : page
    end
  end
end
