# frozen_string_literal: true

module Ci
  class TagsFinder
    def initialize(params:)
      @params = params
    end

    def execute
      tags = all_tags
      filter_by_name(tags)
    end

    private

    def all_tags
      ::Ci::Tag.all
    end

    def filter_by_name(tags)
      return tags unless search.present?

      if search.length >= Gitlab::SQL::Pattern::MIN_CHARS_FOR_PARTIAL_MATCHING
        tags.named_like(search)
      else
        tags.named(search)
      end
    end

    def search
      @params[:search]
    end
  end
end
