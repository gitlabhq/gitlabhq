# frozen_string_literal: true

class Timelog < ApplicationRecord
  validates :time_spent, :user, presence: true
  validate :issuable_id_is_present

  belongs_to :issue, touch: true
  belongs_to :merge_request, touch: true
  belongs_to :user

  scope :for_issues_in_group, -> (group) do
    joins(:issue).where(
      'EXISTS (?)',
      Project.select(1).where(namespace: group.self_and_descendants)
        .where('issues.project_id = projects.id')
    )
  end

  scope :between_dates, -> (start_date, end_date) do
    where('spent_at BETWEEN ? AND ?', start_date, end_date)
  end

  def issuable
    issue || merge_request
  end

  private

  def issuable_id_is_present
    if issue_id && merge_request_id
      errors.add(:base, 'Only Issue ID or Merge Request ID is required')
    elsif issuable.nil?
      errors.add(:base, 'Issue or Merge Request ID is required')
    end
  end

  # Rails5 defaults to :touch_later, overwrite for normal touch
  def belongs_to_touch_method
    :touch
  end
end
