module Gitlab
  module GitalyClient
    class WikiPage
      ATTRS = %i(title format url_path path name historical raw_data).freeze

      include AttributesBag

      def initialize(params)
        super

        # All gRPC strings in a response are frozen, so we get an unfrozen
        # version here so appending to `raw_data` doesn't blow up.
        @raw_data = @raw_data.dup
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
