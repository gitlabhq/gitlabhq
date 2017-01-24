module Bitbucket
  module Representation
    class Base
      def initialize(raw)
        @raw = raw
      end

      def self.decorate(entries)
        entries.map { |entry| new(entry)}
      end

      private

      attr_reader :raw
    end
  end
end
