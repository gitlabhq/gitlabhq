# frozen_string_literal: true

module Autocomplete
  module ActsAsTaggableOn
    class TagsFinder
      LIMIT = 20

      def initialize(taggable_type:, params:)
        @taggable_type = taggable_type
        @params = params
      end

      def execute
        @tags = @taggable_type.all_tags

        search!
        limit!

        @tags
      end

      def search!
        search = @params[:search]

        return unless search

        if search.empty?
          @tags = @taggable_type.none
          return
        end

        @tags =
          if search.length >= Gitlab::SQL::Pattern::MIN_CHARS_FOR_PARTIAL_MATCHING
            @tags.named_like(search)
          else
            @tags.named(search)
          end
      end

      def limit!
        @tags = @tags.limit(LIMIT) # rubocop: disable CodeReuse/ActiveRecord
      end
    end
  end
end
