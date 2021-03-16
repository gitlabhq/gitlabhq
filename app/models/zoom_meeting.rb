# frozen_string_literal: true

class ZoomMeeting < ApplicationRecord
  include Importable
  include UsageStatistics

  belongs_to :project
  belongs_to :issue

  validates :project, presence: true, unless: :importing?
  validates :issue, presence: true, unless: :importing?

  validates :url, presence: true, length: { maximum: 255 }, 'gitlab/utils/zoom_url': true
  validates :issue, same_project_association: true, unless: :importing?

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
