# frozen_string_literal: true

module Bitbucket
  class Paginator
    PAGE_LENGTH = 50 # The minimum length is 10 and the maximum is 100.

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

    def next_url
      page.nil? ? url : page.next
    end

    def fetch_next_page
      parsed_response = connection.get(next_url, pagelen: PAGE_LENGTH, sort: :created_on)
      Page.new(parsed_response, type)
    end
  end
end
