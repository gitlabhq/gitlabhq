# frozen_string_literal: true

class SuggestionSerializer < BaseSerializer
  entity SuggestionEntity

  def represent_diff(resource)
    represent(resource, { only: [:diff_lines] })
  end
end
