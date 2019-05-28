# frozen_string_literal: true

module Suggestions
  class OutdateService
    def execute(merge_request)
      # rubocop: disable CodeReuse/ActiveRecord
      suggestions = merge_request.suggestions.active.includes(:note)

      suggestions.find_in_batches(batch_size: 100) do |group|
        outdatable_suggestion_ids = group.select do |suggestion|
          suggestion.outdated?(cached: false)
        end.map(&:id)

        Suggestion.where(id: outdatable_suggestion_ids).update_all(outdated: true)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
