# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Base
      attr_reader :raw

      class << self
        def decorate(entries)
          entries.map { |entry| new(entry) }
        end

        def convert_timestamp(time_usec)
          # Preserve the original local-time semantics from the monolith. Callers
          # use .to_i for comparison and ActiveRecord stores as UTC regardless, so
          # this is safe. rubocop:disable Rails/TimeZone is intentional.
          Time.at(time_usec / 1000) if time_usec.is_a?(Integer) # rubocop:disable Rails/TimeZone
        end
      end

      def initialize(raw)
        @raw = raw
      end
    end
  end
end
