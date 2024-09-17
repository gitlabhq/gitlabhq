# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class MergeRequestStageEvent < ApplicationRecord
      include StageEventModel
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id merge_request_id group_id project_id start_event_timestamp], presence: true)

      alias_attribute :state, :state_id
      enum state: MergeRequest.available_states, _suffix: true

      belongs_to :issuable, class_name: 'MergeRequest', foreign_key: 'merge_request_id', inverse_of: :merge_request_stage_events

      scope :assigned_to, ->(user) do
        assignees_class = MergeRequestAssignee
        condition = assignees_class.where(user_id: user).where(arel_table[:merge_request_id].eq(assignees_class.arel_table[:merge_request_id]))
        where(condition.arel.exists)
      end

      def self.project_column
        :target_project_id
      end

      def self.issuable_id_column
        :merge_request_id
      end

      def self.issuable_model
        ::MergeRequest
      end

      def self.assignees_model
        MergeRequestAssignee
      end
    end
  end
end
