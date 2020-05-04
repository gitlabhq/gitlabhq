# frozen_string_literal: true

module DesignManagement
  # Service class for counting and caching the number of unresolved
  # notes of a Design
  class DesignUserNotesCountService < ::BaseCountService
    # The version of the cache format. This should be bumped whenever the
    # underlying logic changes. This removes the need for explicitly flushing
    # all caches.
    VERSION = 1

    def initialize(design)
      @design = design
    end

    def relation_for_count
      design.notes.user
    end

    def raw?
      # Since we're storing simple integers we don't need all of the
      # additional Marshal data Rails includes by default.
      true
    end

    def cache_key
      ['designs', 'notes_count', VERSION, design.id]
    end

    private

    attr_reader :design
  end
end
