module AwardEmojiHelper
  def toggle_award_url(awardable)
    if @project
      @__namespace ||= @project.namespace.becomes(Namespace)

      url_for([:toggle_award_emoji, @__namespace, @project, awardable])
    else
      url_for([:toggle_award_emoji, awardable])
    end
  end
end
