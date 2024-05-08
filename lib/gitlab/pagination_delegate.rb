# frozen_string_literal: true

module Gitlab
  class PaginationDelegate # rubocop:disable Gitlab/NamespacedClass
    DEFAULT_PER_PAGE = Kaminari.config.default_per_page
    MAX_PER_PAGE = Kaminari.config.max_per_page

    def initialize(page:, per_page:, count:, options: {})
      @count = count
      @options = { default_per_page: DEFAULT_PER_PAGE,
                   max_per_page: MAX_PER_PAGE }.merge(options)

      @per_page = sanitize_per_page(per_page)
      @page = sanitize_page(page)
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
      limit = begin
        Integer(per_page)
      rescue ArgumentError, TypeError
        nil
      end

      return @options[:default_per_page] unless limit && limit > 0

      [@options[:max_per_page], limit].min
    end

    def sanitize_page(page)
      return 1 unless page && page > 1

      [total_pages, page].min
    end
  end
end
