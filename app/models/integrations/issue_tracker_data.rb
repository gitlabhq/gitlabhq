# frozen_string_literal: true

module Integrations
  class IssueTrackerData < ApplicationRecord
    include BaseDataFields

    attr_encrypted :project_url, encryption_options
    attr_encrypted :issues_url, encryption_options
    attr_encrypted :new_issue_url, encryption_options

    # These length limits are intended to be generous enough to permit any
    # legitimate usage but provide a sensible upper limit.
    validates :project_url, length: { maximum: 2048 }, if: :project_url_changed?
    validates :issues_url, length: { maximum: 2048 }, if: :issues_url_changed?
    validates :new_issue_url, length: { maximum: 2048 }, if: :new_issue_url_changed?
  end
end
