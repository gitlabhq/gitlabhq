# frozen_string_literal: true

module Gitlab
  module ResourceEvents
    class AssignmentEventRecorder
      BATCH_SIZE = 100

      def initialize(parent:, old_assignees:)
        @parent = parent
        @old_assignees = old_assignees
      end

      def record
        case parent
        when Issue
          record_for_parent(
            ::ResourceEvents::IssueAssignmentEvent,
            :issue_id,
            parent,
            old_assignees
          )
        when MergeRequest
          record_for_parent(
            ::ResourceEvents::MergeRequestAssignmentEvent,
            :merge_request_id,
            parent,
            old_assignees
          )
        end
      end

      private

      attr_reader :parent, :old_assignees

      def record_for_parent(resource_klass, foreign_key, parent, old_assignees)
        removed_events = (old_assignees - parent.assignees).map do |unassigned_user|
          {
            foreign_key => parent.id,
            user_id: unassigned_user.id,
            action: :remove
          }
        end.to_set

        added_events = (parent.assignees.to_a - old_assignees).map do |added_user|
          {
            foreign_key => parent.id,
            user_id: added_user.id,
            action: :add
          }
        end.to_set

        (removed_events + added_events).each_slice(BATCH_SIZE) do |events|
          resource_klass.insert_all(events)
        end
      end
    end
  end
end
