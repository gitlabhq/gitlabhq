module AwardEmojiHelper
  def toggle_award_url(awardable)
    if @project
      url_for([:toggle_award_emoji, @project.namespace.becomes(Namespace), @project, awardable])
    else
      url_for([:toggle_award_emoji, awardable])
    end
  end
end
