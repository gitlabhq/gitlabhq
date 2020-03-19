# frozen_string_literal: true

class ZoomMeeting < ApplicationRecord
  include UsageStatistics

  belongs_to :project, optional: false
  belongs_to :issue, optional: false

  validates :url, presence: true, length: { maximum: 255 }, zoom_url: true
  validates :issue, same_project_association: true

  enum issue_status: {
    added: 1,
    removed: 2
  }

  scope :added_to_issue, -> { where(issue_status: :added) }
  scope :removed_from_issue, -> { where(issue_status: :removed) }
  scope :canonical, -> (issue) { where(issue: issue).added_to_issue }

  def self.canonical_meeting(issue)
    canonical(issue)&.take
  end

  def self.canonical_meeting_url(issue)
    canonical_meeting(issue)&.url
  end
end
