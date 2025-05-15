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

      def integer(name, index: false)
        fields << Field::Integer.new(name, index: index)
      end

      def smallint(name, index: false)
        fields << Field::Smallint.new(name, index: index)
      end

      def boolean(name, index: true)
        fields << Field::Boolean.new(name, index: index)
      end

      def keyword(name)
        fields << Field::Keyword.new(name, index: true)
      end

      def text(name)
        fields << Field::Text.new(name, index: false)
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
      class Integer < Field; end
      class Smallint < Field; end
      class Boolean < Field; end
      class Keyword < Field; end
      class Text < Field; end
      class Vector < Field; end
    end
  end
end
