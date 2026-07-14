# frozen_string_literal: true

module BitbucketServer
  class Paginator
    # Should be kept in-sync with `BITBUCKET_SERVER_PAGE_LENGTH` in app/assets/javascripts/import_entities/constants.js
    PAGE_LENGTH = 25

    attr_reader :page_offset

    def initialize(connection, url, type, page_offset: 0, limit: nil)
      @connection = connection
      @type = type
      @url = url
      @page = nil
      @page_offset = page_offset
      @limit = limit
      @total = 0
    end

    def items
      raise StopIteration unless has_next_page?
      raise StopIteration if over_limit?

      @page = fetch_next_page
      @total += @page.items.count
      @page.items
    end

    def has_next_page?
      page.nil? || page.next?
    end

    private

    attr_reader :connection, :page, :url, :type, :limit

    def over_limit?
      return false unless @limit

      @limit > 0 && @total >= @limit
    end

    def next_offset
      page.nil? ? starting_offset : page.next
    end

    def starting_offset
      [0, page_offset - 1].max * max_per_page
    end

    def max_per_page
      limit || PAGE_LENGTH
    end

    def fetch_next_page
      parsed_response = connection.get(@url, start: next_offset, limit: max_per_page)
      Page.new(parsed_response, type)
    end
  end
end
