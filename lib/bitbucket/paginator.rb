module Bitbucket
  class Paginator
    PAGE_LENGTH = 50 # The minimum length is 10 and the maximum is 100.

    def initialize(connection, url, type)
      @connection = connection
      @type = type
      @url = url
      @page = nil

      connection.query(pagelen: PAGE_LENGTH, sort: :created_on)
    end

    def next
      raise StopIteration unless has_next_page?

      @page = fetch_next_page
      @page.items
    end

    private

    attr_reader :connection, :page, :url, :type

    def has_next_page?
      page.nil? || page.next?
    end

    def page_url
      page.nil? ? url : page.next
    end

    def fetch_next_page
      parsed_response = connection.get(page_url)
      Page.new(parsed_response, type)
    end
  end
end
