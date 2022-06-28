# frozen_string_literal: true

module Ci
  module BulkInsertableTags
    extend ActiveSupport::Concern

    BULK_INSERT_TAG_THREAD_KEY = 'ci_bulk_insert_tags'

    class << self
      def with_bulk_insert_tags
        previous = Thread.current[BULK_INSERT_TAG_THREAD_KEY]
        Thread.current[BULK_INSERT_TAG_THREAD_KEY] = true
        yield
      ensure
        Thread.current[BULK_INSERT_TAG_THREAD_KEY] = previous
      end
    end

    # overrides save_tags from acts-as-taggable
    def save_tags
      super unless Thread.current[BULK_INSERT_TAG_THREAD_KEY]
    end
  end
end
