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
    next if suggestion.appliable?

    case suggestion.inapplicable_reason
    when :merge_request_merged
      _("This merge request was merged. To apply this suggestion, edit this file directly.")
    when :merge_request_closed
      _("This merge request is closed. To apply this suggestion, edit this file directly.")
    when :source_branch_deleted
      _("Can't apply as the source branch was deleted.")
    when :outdated
      phrase = suggestion.single_line? ? 'this line was' : 'these lines were'

      _("Can't apply as %{phrase} changed in a more recent version.") % { phrase: phrase }
    when :same_content
      _("This suggestion already matches its content.")
    else
      _("Can't apply this suggestion.")
    end
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
