module EE
  module AwardEmojiHelper
    extend ::Gitlab::Utils::Override

    override :toggle_award_url
    def toggle_award_url(awardable)
      if awardable.is_a?(Note) && awardable.for_epic?
        return toggle_award_emoji_group_epic_note_path(awardable.noteable.group, awardable.noteable, awardable)
      elsif awardable.is_a?(Epic)
        return toggle_award_emoji_group_epic_path(awardable.group, awardable)
      end

      super
    end
  end
end
