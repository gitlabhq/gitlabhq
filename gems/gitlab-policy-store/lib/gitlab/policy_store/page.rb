# frozen_string_literal: true

require 'forwardable'

module Gitlab
  module PolicyStore
    class Page
      include Enumerable
      extend Forwardable

      def_delegators :items, :size, :empty?, :first, :to_a

      attr_reader :items, :per_page

      def initialize(items:, per_page:, has_next_page:)
        @items = items
        @per_page = per_page
        @has_next_page = has_next_page

        freeze
      end

      def has_next_page?
        @has_next_page
      end

      def each(&block)
        items.each(&block)
      end

      def ==(other)
        return items == other.items if other.is_a?(Page)

        items == other
      end
    end
  end
end
