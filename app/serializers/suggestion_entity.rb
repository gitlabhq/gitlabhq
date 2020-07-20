# frozen_string_literal: true

class SuggestionEntity < API::Entities::Suggestion
  include RequestAwareEntity
  include Gitlab::Utils::StrongMemoize

  unexpose :from_line, :to_line, :from_content, :to_content
  expose :diff_lines, using: DiffLineEntity do |suggestion|
    Gitlab::Diff::Highlight.new(suggestion.diff_lines).highlight
  end
  expose :current_user do
    expose :can_apply do |suggestion|
      can_apply?(suggestion)
    end
  end

  expose :inapplicable_reason do |suggestion|
    next _("You don't have write access to the source branch.") unless can_apply?(suggestion)

    suggestion.inapplicable_reason
  end

  private

  def current_user
    request.current_user
  end

  def can_apply?(suggestion)
    strong_memoize(:can_apply) do
      Ability.allowed?(current_user, :apply_suggestion, suggestion)
    end
  end
end
