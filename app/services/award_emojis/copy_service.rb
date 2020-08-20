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
        new_award.save!
      end

      ServiceResponse.success
    end

    private

    attr_accessor :from_awardable, :to_awardable
  end
end
