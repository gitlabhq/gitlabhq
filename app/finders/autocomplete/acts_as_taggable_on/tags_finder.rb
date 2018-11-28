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
        @tags = ::ActsAsTaggableOn::Tag.all

        filter_by_taggable_type!
        search!
        limit!

        @tags
      end

      def filter_by_taggable_type!
        # rubocop: disable CodeReuse/ActiveRecord
        @tags = @tags
          .joins(:taggings)
          .where(taggings: { taggable_type: @taggable_type.name })
          .distinct
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def search!
        search = @params[:search]

        return unless search

        if search.empty?
          @tags = ::ActsAsTaggableOn::Tag.none
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
