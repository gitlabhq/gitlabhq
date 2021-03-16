# frozen_string_literal: true

# This should be in the ErrorTracking namespace. For more details, see:
# https://gitlab.com/gitlab-org/gitlab/-/issues/323342
module Gitlab
  module ErrorTracking
    class ErrorEvent
      include ActiveModel::Model

      attr_accessor :issue_id, :date_received, :stack_trace_entries, :gitlab_project

      def self.declarative_policy_class
        'ErrorTracking::BasePolicy'
      end
    end
  end
end
