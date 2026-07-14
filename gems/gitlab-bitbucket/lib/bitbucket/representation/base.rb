# frozen_string_literal: true

module Bitbucket
  module Representation
    class Base
      attr_reader :raw

      delegate :present?, to: :raw

      def self.decorate(entries)
        entries.map { |entry| new(entry) }
      end

      def initialize(raw)
        @raw = raw
      end
    end
  end
end
