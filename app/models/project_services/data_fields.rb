# frozen_string_literal: true

module DataFields
  extend ActiveSupport::Concern

  included do
    has_one :issue_tracker_data
    has_one :jira_tracker_data
  end
end
