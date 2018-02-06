module Gitlab
  module GitalyClient
    class WikiPage
      ATTRS = %i(title format url_path path name historical raw_data).freeze

      include AttributesBag
      include Gitlab::EncodingHelper

      def initialize(params)
        super

        # All gRPC strings in a response are frozen, so we get an unfrozen
        # version here so appending to `raw_data` doesn't blow up.
        @raw_data = @raw_data.dup

        @title = encode_utf8(@title)
        @path = encode_utf8(@path)
        @name = encode_utf8(@name)
      end

      def historical?
        @historical
      end

      def format
        @format.to_sym
      end
    end
  end
end
