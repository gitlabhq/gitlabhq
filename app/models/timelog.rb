# frozen_string_literal: true

class Timelog < ActiveRecord::Base
  validates :time_spent, :user, presence: true
  validate :issuable_id_is_present

  belongs_to :issue, touch: true
  belongs_to :merge_request, touch: true
  belongs_to :user

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
