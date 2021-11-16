# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class IssueStageEvent < ApplicationRecord
      include StageEventModel
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id issue_id group_id project_id start_event_timestamp], presence: true)

      alias_attribute :state, :state_id
      enum state: Issue.available_states, _suffix: true

      scope :assigned_to, ->(user) do
        assignees_class = IssueAssignee
        condition = assignees_class.where(user_id: user).where(arel_table[:issue_id].eq(assignees_class.arel_table[:issue_id]))
        where(condition.arel.exists)
      end

      def self.issuable_id_column
        :issue_id
      end

      def self.issuable_model
        ::Issue
      end
    end
  end
end
