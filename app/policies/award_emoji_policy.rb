# frozen_string_literal: true

class AwardEmojiPolicy < BasePolicy
  delegate { @subject.awardable if DeclarativePolicy.has_policy?(@subject.awardable) }

  condition(:can_read_awardable) do
    can?(:"read_#{@subject.awardable.to_ability_name}")
  end

  rule { can_read_awardable }.enable :read_emoji
end
