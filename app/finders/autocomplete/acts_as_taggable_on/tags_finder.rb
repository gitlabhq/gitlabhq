# frozen_string_literal: true

module Autocomplete
  module ActsAsTaggableOn
    class TagsFinder
      LIMIT = 20

      def initialize(params:)
        @params = params
      end

      def execute
        tags = all_tags
        tags = filter_by_name(tags)
        limit(tags)
      end

      private

      def all_tags
        ::ActsAsTaggableOn::Tag.all
      end

      def filter_by_name(tags)
        return tags unless search.present?

        if search.length >= Gitlab::SQL::Pattern::MIN_CHARS_FOR_PARTIAL_MATCHING
          tags.named_like(search)
        else
          tags.named(search)
        end
      end

      def limit(tags)
        tags.limit(LIMIT) # rubocop: disable CodeReuse/ActiveRecord
      end

      def search
        @params[:search]
      end
    end
  end
end
