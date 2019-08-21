# frozen_string_literal: true

module AwardEmojis
  class DestroyService < AwardEmojis::BaseService
    def execute
      unless awardable.user_can_award?(current_user)
        return error('User cannot destroy emoji on the awardable', status: :forbidden)
      end

      awards = AwardEmojisFinder.new(awardable, name: name, awarded_by: current_user).execute

      if awards.empty?
        return error("User has not awarded emoji of type #{name} on the awardable", status: :forbidden)
      end

      award = awards.destroy_all.first # rubocop: disable DestroyAll

      success(award: award)
    end
  end
end
