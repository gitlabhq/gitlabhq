# frozen_string_literal: true

module Integrations
  class IssueTrackerData < ApplicationRecord
    include BaseDataFields

    attr_encrypted :project_url, encryption_options
    attr_encrypted :issues_url, encryption_options
    attr_encrypted :new_issue_url, encryption_options
  end
end
