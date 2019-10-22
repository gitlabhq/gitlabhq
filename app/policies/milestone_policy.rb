# frozen_string_literal: true

class MilestonePolicy < BasePolicy
  delegate { @subject.resource_parent }
end
