# frozen_string_literal: true

class MilestonePolicy < BasePolicy
  delegate { @subject.parent }
end
