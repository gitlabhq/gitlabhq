# frozen_string_literal: true

module Bitbucket
  module Representation
    class Base
      attr_reader :raw

      delegate :present?, to: :raw

      def initialize(raw)
        @raw = raw
      end

      def self.decorate(entries)
        entries.map { |entry| new(entry) }
      end
    end
  end
end
