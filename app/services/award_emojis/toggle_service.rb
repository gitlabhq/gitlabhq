# frozen_string_literal: true

module AwardEmojis
  class ToggleService < AwardEmojis::BaseService
    def execute
      if awardable.awarded_emoji?(name, current_user)
        DestroyService.new(awardable, name, current_user).execute
      else
        AddService.new(awardable, name, current_user).execute
      end
    end
  end
end
