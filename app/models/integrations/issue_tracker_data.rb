# frozen_string_literal: true

module Integrations
  class IssueTrackerData < ApplicationRecord
    include BaseDataFields

    ignore_column :instance_integration_id, remove_with: '18.7', remove_after: '2025-11-20'

    attr_encrypted :project_url, encryption_options
    attr_encrypted :issues_url, encryption_options
    attr_encrypted :new_issue_url, encryption_options
  end
end
