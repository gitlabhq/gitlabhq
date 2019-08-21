# frozen_string_literal: true

# Class for retrieving information about emoji awarded _by_ a particular user.
module AwardEmojis
  class CollectUserEmojiService
    attr_reader :current_user

    # current_user - The User to generate the data for.
    def initialize(current_user = nil)
      @current_user = current_user
    end

    def execute
      return [] unless current_user

      # We want the resulting data set to be an Array containing the emoji names
      # in descending order, based on how often they were awarded.
      AwardEmoji
        .award_counts_for_user(current_user)
        .map { |name, _| { name: name } }
    end
  end
end
