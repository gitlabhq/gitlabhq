module AwardEmojiHelper
  def toggle_award_url(awardable)
    unless awardable.is_a?(Snippet)
      return url_for([:toggle_award_emoji, @project.namespace.becomes(Namespace), @project, awardable])
    end

    if awardable.is_a?(ProjectSnippet)
      toggle_award_emoji_namespace_project_snippet_path(@project.namespace.becomes(Namespace), @project, awardable)
    else
      toggle_award_emoji_snippet_url(awardable)
    end
  end
end
