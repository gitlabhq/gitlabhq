module AwardEmojiHelper
  def toggle_award_url(awardable)
    return url_for([:toggle_award_emoji, awardable]) unless @project || awardable.is_a?(Note)

    if awardable.is_a?(Note)
      # We render a list of notes very frequently and calling the specific method is a lot faster than the generic one (4.5x)
      if awardable.for_personal_snippet?
        toggle_award_emoji_snippet_note_path(awardable.noteable, awardable)
      else
        toggle_award_emoji_project_note_path(@project, awardable.id)
      end
    else
      url_for([:toggle_award_emoji, @project.namespace.becomes(Namespace), @project, awardable])
    end
  end
end
