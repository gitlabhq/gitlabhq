# frozen_string_literal: true

module Bitbucket
  class Paginator
    PAGE_LENGTH = 50 # The minimum length is 10 and the maximum is 100.

    def initialize(connection, url, type, page_number: nil, limit: nil, after_cursor: nil)
      @connection = connection
      @type = type
      @url = url
      @page_number = page_number
      @limit = limit
      @after_cursor = after_cursor
      @total = 0
    end

    def items
      raise StopIteration if over_limit?
      raise StopIteration unless has_next_page?

      @page = fetch_next_page
      @total += @page.items.count
      @page.items
    end

    def page_info
      {
        has_next_page: page.attrs[:next].present?,
        start_cursor: @after_cursor,
        end_cursor: next_page_cursor
      }
    end

    private

    attr_reader :connection, :page, :url, :type, :page_number, :limit, :after_cursor

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

    def fetch_next_page
      extra_query = { pagelen: max_per_page }
      extra_query[:page] = page_number if page_number && limit
      extra_query[:after] = after_cursor if after_cursor && page.nil?

      parsed_response = connection.get(next_url, extra_query)
      Page.new(parsed_response, type)
    end

    def next_page_cursor
      return unless page.next?

      Rack::Utils.parse_nested_query(URI.parse(next_url).query)['after']
    end
  end
end
