# frozen_string_literal: true

module Gitlab
  module Git
    class Changes
      include Enumerable

      attr_reader :repository_data

      def initialize
        @refs = Set.new
        @items = []
        @branches_index = []
        @tags_index = []
        @repository_data = []
      end

      def includes_branches?
        branches_index.any?
      end

      def includes_tags?
        tags_index.any?
      end

      def add_branch_change(change)
        @branches_index << add_change(change)
        self
      end

      def add_tag_change(change)
        @tags_index << add_change(change)
        self
      end

      def each
        items.each do |item|
          yield item
        end
      end

      def refs
        @refs.to_a
      end

      def branch_changes
        items.values_at(*branches_index)
      end

      def tag_changes
        items.values_at(*tags_index)
      end

      private

      attr_reader :items, :branches_index, :tags_index

      def add_change(change)
        # refs and repository_data are being cached when a change is added to
        # the collection to remove the need to iterate through changes multiple
        # times.
        @refs << change[:ref]
        @repository_data << build_change_repository_data(change)
        @items << change

        @items.size - 1
      end

      def build_change_repository_data(change)
        DataBuilder::Repository.single_change(change[:oldrev], change[:newrev], change[:ref])
      end
    end
  end
end
