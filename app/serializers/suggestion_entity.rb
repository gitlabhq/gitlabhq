# frozen_string_literal: true

class SuggestionEntity < API::Entities::Suggestion
  include RequestAwareEntity

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
