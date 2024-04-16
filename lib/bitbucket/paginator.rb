# frozen_string_literal: true

module Bitbucket
  class Paginator
    PAGE_LENGTH = 50 # The minimum length is 10 and the maximum is 100.

    def initialize(connection, url, type, page_number: nil, limit: nil)
      @connection = connection
      @type = type
      @url = url
      @page_number = page_number
      @limit = limit
      @total = 0
    end

    def items
      raise StopIteration if over_limit?
      raise StopIteration unless has_next_page?

      @page = fetch_next_page
      @total += @page.items.count
      @page.items
    end

    private

    attr_reader :connection, :page, :url, :type, :page_number, :limit

    def has_next_page?
      page.nil? || page.next?
    end

    def next_url
      page.nil? ? url : page.next
    end

    def max_per_page
      limit || PAGE_LENGTH
    end

    def over_limit?
      return false unless limit

      limit > 0 && @total >= limit
    end

    # Note to self for specs:
    # - Allowed pagelen to be set by limit instead of just using PAGE_LENGTH
    # - Allow specifying a starting page to grab one page at a time, so PageCounter can be used for logging
    # - Added over_limit? to make sure only one page is called.
    def fetch_next_page
      extra_query = { pagelen: max_per_page }
      extra_query[:page] = page_number if page_number && limit

      parsed_response = connection.get(next_url, extra_query)
      Page.new(parsed_response, type)
    end
  end
end
