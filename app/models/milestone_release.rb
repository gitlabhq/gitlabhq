# frozen_string_literal: true

class MilestoneRelease < ApplicationRecord
  belongs_to :milestone
  belongs_to :release

  validate :same_project_between_milestone_and_release

  private

  def same_project_between_milestone_and_release
    return if milestone&.project_id == release&.project_id

    errors.add(:base, 'does not have the same project as the milestone')
  end
end
