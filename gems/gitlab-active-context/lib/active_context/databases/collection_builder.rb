# frozen_string_literal: true

module ActiveContext
  module Databases
    class CollectionBuilder
      attr_reader :fields

      def initialize
        @fields = []
      end

      def bigint(name, index: false)
        fields << Field::Bigint.new(name, index: index)
      end

      def prefix(name)
        fields << Field::Prefix.new(name, index: true)
      end

      def vector(name, dimensions:, index: true)
        fields << Field::Vector.new(name, dimensions: dimensions, index: index)
      end
    end

    class Field
      attr_reader :name, :options

      def initialize(name, **options)
        @name = name.to_s
        @options = options
      end

      class Bigint < Field; end
      class Prefix < Field; end
      class Vector < Field; end
    end
  end
end
