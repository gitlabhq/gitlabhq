module Github
  module Representation
    class Base
      def initialize(raw)
        @raw = raw
      end

      private

      attr_reader :raw
    end
  end
end
