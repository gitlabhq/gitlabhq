# frozen_string_literal: true

module Gitlab
  module Utils
    # Parses Link http headers (as defined in https://www.rfc-editor.org/rfc/rfc5988.txt)
    #
    # The URI-references with their relation type are extracted and returned as a hash
    # Example:
    #
    # header = '<http://test.org/TheBook/chapter2>; rel="previous", <http://test.org/TheBook/chapter4>; rel="next"'
    #
    # Gitlab::Utils::LinkHeaderParser.new(header).parse
    # {
    #   previous: {
    #     uri: #<URI::HTTP http://test.org/TheBook/chapter2>
    #   },
    #   next: {
    #     uri: #<URI::HTTP http://test.org/TheBook/chapter4>
    #   }
    # }
    class LinkHeaderParser
      REL_PATTERN = %r{rel="(\w+)"}
      # to avoid parse really long URIs we limit the amount of characters allowed
      URI_PATTERN = %r{<(.{1,500})>}

      def initialize(header)
        @header = header
      end

      def parse
        return {} if @header.blank?

        links = @header.split(',')
        result = {}
        links.each do |link|
          direction = link[REL_PATTERN, 1]&.to_sym
          uri = link[URI_PATTERN, 1]

          result[direction] = { uri: URI(uri) } if direction && uri
        end

        result
      end
    end
  end
end
