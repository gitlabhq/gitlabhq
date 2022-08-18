# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Base
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      def self.decorate(entries)
        entries.map { |entry| new(entry) }
      end

      def self.convert_timestamp(time_usec)
        Time.at(time_usec / 1000) if time_usec.is_a?(Integer)
      end
    end
  end
end
