# frozen_string_literal: true

module Issuable
  module Callbacks
    class Milestone < Base
      ALLOWED_PARAMS = %i[milestone milestone_id skip_milestone_email].freeze

      def after_initialize
        params[:milestone_id] = nil if excluded_in_new_type?
        return unless params.key?(:milestone_id) && has_permission?(:"set_#{issuable.to_ability_name}_metadata")

        @old_milestone = issuable.milestone

        if params[:milestone_id].blank? || params[:milestone_id].to_s == IssuableFinder::Params::NONE
          issuable.milestone = nil

          return
        end

        resource_group = issuable.project&.group || issuable.try(:namespace)
        project_ids = [issuable.project&.id].compact

        milestone = MilestonesFinder.new({
          project_ids: project_ids,
          group_ids: resource_group&.self_and_ancestors&.select(:id),
          ids: [params[:milestone_id]]
        }).execute.first

        issuable.milestone = milestone if milestone
      end

      def after_update_commit
        return unless issuable.previous_changes.include?('milestone_id')

        update_usage_data_counters
        send_milestone_change_notification

        GraphqlTriggers.issuable_milestone_updated(issuable)
      end

      def after_save_commit
        return unless issuable.previous_changes.include?('milestone_id')

        invalidate_milestone_counters
      end

      private

      def invalidate_milestone_counters
        [@old_milestone, issuable.milestone].compact.each do |milestone|
          case issuable
          when Issue
            ::Milestones::ClosedIssuesCountService.new(milestone).delete_cache
            ::Milestones::IssuesCountService.new(milestone).delete_cache
          when MergeRequest
            ::Milestones::MergeRequestsCountService.new(milestone).delete_cache
          end
        end
      end

      def update_usage_data_counters
        return unless issuable.is_a?(MergeRequest)

        Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
          .track_milestone_changed_action(user: current_user)
      end

      def send_milestone_change_notification
        return if params[:skip_milestone_email]

        notification_service = NotificationService.new.async

        if issuable.milestone.nil?
          notification_service.removed_milestone(issuable, current_user)
        else
          notification_service.changed_milestone(issuable, issuable.milestone, current_user)
        end
      end
    end
  end
end
