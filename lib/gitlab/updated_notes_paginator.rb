# frozen_string_literal: true

module Gitlab
  # UpdatedNotesPaginator implements a rudimentary form of keyset pagination on
  # top of a notes relation that has been initialized with a `last_fetched_at`
  # value. This class will attempt to limit the number of notes returned, and
  # specify a new value for `last_fetched_at` that will pick up where the last
  # page of notes left off.
  class UpdatedNotesPaginator
    LIMIT = 50
    MICROSECOND = 1_000_000

    attr_reader :next_fetched_at, :notes

    def initialize(relation, last_fetched_at:)
      @last_fetched_at = last_fetched_at
      @now = Time.current

      notes, more = fetch_page(relation)
      if more
        init_middle_page(notes)
      else
        init_final_page(notes)
      end
    end

    def metadata
      { last_fetched_at: next_fetched_at_microseconds, more: more }
    end

    private

    attr_reader :last_fetched_at, :more, :now

    def next_fetched_at_microseconds
      (next_fetched_at.to_i * MICROSECOND) + next_fetched_at.usec
    end

    def fetch_page(relation)
      relation = relation.order_updated_asc.with_order_id_asc
      notes = relation.limit(LIMIT + 1).to_a

      return [notes, false] unless notes.size > LIMIT

      marker = notes.pop # Remove the marker note

      # Although very unlikely, it is possible that more notes with the same
      # updated_at may exist, e.g., if created in bulk. Add them all to the page
      # if this is detected, so pagination won't get stuck indefinitely
      if notes.last.updated_at == marker.updated_at
        notes += relation
          .with_updated_at(marker.updated_at)
          .id_not_in(notes.map(&:id))
          .to_a
      end

      [notes, true]
    end

    def init_middle_page(notes)
      @more = true

      # The fetch overlap can be ignored if we're in an intermediate page.
      @next_fetched_at = notes.last.updated_at + NotesFinder::FETCH_OVERLAP
      @notes = notes
    end

    def init_final_page(notes)
      @more = false
      @next_fetched_at = now
      @notes = notes
    end
  end
end
