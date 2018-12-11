# frozen_string_literal: true

module Autocomplete
  module ActsAsTaggableOn
    class TagsFinder
      LIMIT = 20

      def initialize(params:)
        @params = params
      end

      def execute
        @tags = ::ActsAsTaggableOn::Tag.all

        search!
        limit!

        @tags
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
