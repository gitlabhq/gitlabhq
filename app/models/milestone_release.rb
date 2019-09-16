# frozen_string_literal: true

class MilestoneRelease < ApplicationRecord
  belongs_to :milestone
  belongs_to :release

  validate :same_project_between_milestone_and_release

  # Keep until 2019-11-29
  self.ignored_columns += %i[id]

  private

  def same_project_between_milestone_and_release
    return if milestone&.project_id == release&.project_id

    errors.add(:base, 'does not have the same project as the milestone')
  end
end
