# frozen_string_literal: true

# This concern is used by registered integrations such as Integrations::TeamCity and
# Integrations::DroneCi and adds methods to perform validations on the received
# data.
module Integrations
  module PushDataValidations
    extend ActiveSupport::Concern

    def merge_request_valid?(data)
      attrs = data[:object_attributes]
      return false unless attrs

      # oldrev is only set when the source branch head moved, so gating 'update' on it
      # avoids spurious builds for label/title/assignee changes.
      attrs[:state] == 'opened' &&
        (%w[open reopen].include?(attrs[:action]) ||
          (attrs[:action] == 'update' && attrs[:oldrev].present?))
    end

    def push_valid?(data)
      data[:total_commits_count] > 0 &&
        !branch_removed?(data) &&
        # prefer merge request trigger over push to avoid double builds
        !opened_merge_requests?(data)
    end

    def tag_push_valid?(data)
      data[:total_commits_count] > 0 && !branch_removed?(data)
    end

    private

    def branch_removed?(data)
      Gitlab::Git.blank_ref?(data[:after])
    end

    def opened_merge_requests?(data)
      project.merge_requests
        .opened
        .from_project(project)
        .from_source_branches(Gitlab::Git.ref_name(data[:ref]))
        .exists?
    end
  end
end
