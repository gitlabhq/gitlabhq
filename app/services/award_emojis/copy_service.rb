# frozen_string_literal: true

# This service copies AwardEmoji from one Awardable to another.
#
# It expects the calling code to have performed the necessary authorization
# checks in order to allow the copy to happen.
module AwardEmojis
  class CopyService
    def initialize(from_awardable, to_awardable)
      raise ArgumentError, 'Awardables must be different' if from_awardable == to_awardable

      @from_awardable = from_awardable
      @to_awardable = to_awardable
    end

    def execute
      from_awardable.award_emoji.find_each do |award|
        new_award = award.dup
        new_award.awardable = to_awardable
        # In some instances when an awardable has a custom emoji and is being moved to a namespace where this
        # emoji does not exist the save! will raise a validation exception.
        # see `AwardEmoji`: validates :name, presence: true, 'gitlab/emoji_name': true
        #
        # We can skip copying custom emoji for now: https://gitlab.com/gitlab-org/gitlab/-/issues/501193#note_2186334353
        new_award.save! if new_award.valid?
      end

      ServiceResponse.success
    end

    private

    attr_accessor :from_awardable, :to_awardable
  end
end
