# frozen_string_literal: true

class ZoomMeeting < ApplicationRecord
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
end
