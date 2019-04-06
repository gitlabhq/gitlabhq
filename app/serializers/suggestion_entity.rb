# frozen_string_literal: true

class SuggestionEntity < API::Entities::Suggestion
  include RequestAwareEntity

  unexpose :from_line, :to_line, :from_content, :to_content
  expose :diff_lines, using: DiffLineEntity
  expose :current_user do
    expose :can_apply do |suggestion|
      Ability.allowed?(current_user, :apply_suggestion, suggestion)
    end
  end

  private

  def current_user
    request.current_user
  end
end
