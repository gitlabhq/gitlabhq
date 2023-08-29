# frozen_string_literal: true

module Suggestions
  class CreateService
    def initialize(note)
      @note = note
    end

    def execute
      return unless @note.supports_suggestion?

      suggestions = Gitlab::Diff::SuggestionsParser.parse(
        @note.note,
        project: @note.project,
        position: @note.position
      )

      rows = suggestions.map.with_index do |suggestion, index|
        creation_params = suggestion.to_hash.slice(
          :from_content,
          :to_content,
          :lines_above,
          :lines_below
        )

        creation_params.merge!(note_id: @note.id, relative_order: index)
      end

      rows.in_groups_of(100, false) do |rows|
        ApplicationRecord.legacy_bulk_insert('suggestions', rows) # rubocop:disable Gitlab/BulkInsert
      end

      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_add_suggestion_action(note: @note)
    end
  end
end
