module Github
  module Representation
    class Base
      def initialize(raw)
        @raw = raw
      end

      def url
        raw['url']
      end

      def created_at
        raw['created_at']
      end

      def updated_at
        raw['updated_at']
      end

      private

      attr_reader :raw
    end
  end
end
