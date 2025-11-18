# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class TagRegistry
      attr_reader :tags

      def initialize
        @tags = []
      end

      def register(tag)
        return if tag_exists?(tag)

        tags << tag.to_h
      end

      def to_h
        { tags: @tags }
      end

      private

      def tag_exists?(tag)
        tags.any? { |existing_tag| existing_tag[:name] == tag.name }
      end
    end
  end
end
