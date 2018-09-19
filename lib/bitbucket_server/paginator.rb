# frozen_string_literal: true

module BitbucketServer
  class Paginator
    PAGE_LENGTH = 25

    def initialize(connection, url, type)
      @connection = connection
      @type = type
      @url = url
      @page = nil
    end

    def items
      raise StopIteration unless has_next_page?

      @page = fetch_next_page
      @page.items
    end

    private

    attr_reader :connection, :page, :url, :type

    def has_next_page?
      page.nil? || page.next?
    end

    def next_offset
      page.nil? ? 0 : page.next
    end

    def fetch_next_page
      parsed_response = connection.get(@url, start: next_offset, limit: PAGE_LENGTH)
      Page.new(parsed_response, type)
    end
  end
end
