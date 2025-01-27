# frozen_string_literal: true

# This module is used to define quick actions for issues and merge requests.
#

module Gitlab
  module QuickActions
    module IssueAndMergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        ########################################################################
        #
        # /assign
        #
        desc { _('Assign') }
        explanation do |users|
          _('Assigns %{assignee_users_sentence}.') % { assignee_users_sentence: assignee_users_sentence(users) }
        end
        execution_message do |users = nil|
          if users.blank?
            _("Failed to assign a user because no user was found.")
          else
            users = [users.first] unless quick_action_target.allows_multiple_assignees?

            _('Assigned %{assignee_users_sentence}.') % { assignee_users_sentence: assignee_users_sentence(users) }
          end
        end
        params do
          quick_action_target.allows_multiple_assignees? ? '@user1 @user2' : '@user'
        end
        types Issue, MergeRequest
        condition do
          quick_action_target.supports_assignee? && current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        parse_params do |assignee_param|
          extract_users(assignee_param)
        end
        command :assign do |users|
          next if users.empty?

          if quick_action_target.allows_multiple_assignees?
            @updates[:assignee_ids] ||= quick_action_target.assignees.map(&:id)
            @updates[:assignee_ids] |= users.map(&:id)
          else
            @updates[:assignee_ids] = [users.first.id]
          end
        end

        ########################################################################
        #
        # /unassign
        #
        desc do
          if quick_action_target.allows_multiple_assignees?
            _('Remove all or specific assignees')
          else
            _('Remove assignee')
          end
        end
        explanation do |users = nil|
          assignees = assignees_for_removal(users)
          _("Removes %{assignee_text} %{assignee_references}.") %
            { assignee_text: 'assignee'.pluralize(assignees.size), assignee_references: assignees.map(&:to_reference).to_sentence }
        end
        execution_message do |users = nil|
          assignees = assignees_for_removal(users)
          _("Removed %{assignee_text} %{assignee_references}.") %
            { assignee_text: 'assignee'.pluralize(assignees.size), assignee_references: assignees.map(&:to_reference).to_sentence }
        end
        params do
          quick_action_target.allows_multiple_assignees? ? '@user1 @user2' : ''
        end
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.assignees.any? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        parse_params do |unassign_param|
          # When multiple users are assigned, all will be unassigned if multiple assignees are no longer allowed
          extract_users(unassign_param) if quick_action_target.allows_multiple_assignees?
        end
        command :unassign do |users = nil|
          if quick_action_target.allows_multiple_assignees? && users&.any?
            @updates[:assignee_ids] ||= quick_action_target.assignees.map(&:id)
            @updates[:assignee_ids] -= users.map(&:id)
          else
            @updates[:assignee_ids] = []
          end
        end

        ########################################################################
        #
        # /milestone
        #
        desc { _('Set milestone') }
        explanation do |milestone|
          _("Sets the milestone to %{milestone_reference}.") % { milestone_reference: milestone.to_reference(full: true, absolute_path: true) } if milestone
        end
        execution_message do |milestone|
          _("Set the milestone to %{milestone_reference}.") % { milestone_reference: milestone.to_reference } if milestone
        end
        params '%"milestone"'
        types Issue, MergeRequest
        condition do
          quick_action_target.supports_milestone? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target) &&
            find_milestones(project, state: 'active').any?
        end
        parse_params do |milestone_param|
          extract_references(milestone_param, :milestone).first ||
            find_milestones(project, title: milestone_param.strip).first
        end
        command :milestone do |milestone|
          @updates[:milestone_id] = milestone.id if milestone
        end

        ########################################################################
        #
        # /remove_milestone
        #
        desc { _('Remove milestone') }
        explanation do
          _("Removes %{milestone_reference} milestone.") % { milestone_reference: quick_action_target.milestone.to_reference(full: true, absolute_path: true) }
        end
        execution_message do
          _("Removed %{milestone_reference} milestone.") % { milestone_reference: quick_action_target.milestone.to_reference }
        end
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.milestone_id? &&
            quick_action_target.supports_milestone? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        command :remove_milestone do
          @updates[:milestone_id] = nil
        end

        ########################################################################
        #
        # /copy_metadata
        #
        desc { _('Copy labels and milestone from other work item or merge request in the same namespace') }
        explanation do |source_issuable|
          _("Copy labels and milestone from %{source_issuable_reference}.") % { source_issuable_reference: source_issuable.to_reference }
        end
        params '#item | !merge_request | URL'
        types Issue, MergeRequest, WorkItem
        condition do
          current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        parse_params do |issuable_param|
          extract_references(issuable_param, :issue).first ||
            extract_references(issuable_param, :work_item).first ||
            extract_references(issuable_param, :epic).first ||
            extract_references(issuable_param, :merge_request).first ||
            failed_parse(_("Failed to find work item or merge request"))
        end
        command :copy_metadata do |source_issuable|
          if can_copy_metadata?(source_issuable)
            @updates[:add_label_ids] = source_issuable.labels.map(&:id)
            @updates[:milestone_id] = source_issuable.milestone.id if source_issuable.milestone

            @execution_message[:copy_metadata] = _("Copied labels and milestone from %{source_issuable_reference}.") % { source_issuable_reference: source_issuable.to_reference }
          end
        end

        ########################################################################
        #
        # /estimate
        #
        desc { _('Set time estimate') }
        explanation do |time_estimate|
          next unless time_estimate

          if time_estimate == 0
            _('Removes time estimate.')
          elsif time_estimate > 0
            formatted_time_estimate = format_time_estimate(time_estimate)
            _("Sets time estimate to %{time_estimate}.") % { time_estimate: formatted_time_estimate } if formatted_time_estimate
          end
        end
        execution_message do |time_estimate|
          next _('Removed time estimate.') if time_estimate == 0

          formatted_time_estimate = format_time_estimate(time_estimate)
          _("Set time estimate to %{time_estimate}.") % { time_estimate: formatted_time_estimate } if formatted_time_estimate
        end
        params '<1w 3d 2h 14m>'
        types Issue, MergeRequest
        condition do
          quick_action_target.supports_time_tracking? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        parse_params do |raw_duration|
          Gitlab::TimeTrackingFormatter.parse(raw_duration, keep_zero: true)
        end
        command :estimate, :estimate_time do |time_estimate|
          @updates[:time_estimate] = time_estimate
        end

        ########################################################################
        #
        # /spend, /spent, /spend_time
        #
        desc { _('Add or subtract spent time') }
        explanation do |time_spent, time_spent_date|
          spend_time_message(time_spent, time_spent_date, false)
        end
        execution_message do |time_spent, time_spent_date|
          spend_time_message(time_spent, time_spent_date, true)
        end

        params do
          base_params = 'time(1h30m | -1h30m) <date(YYYY-MM-DD)>'
          if Feature.enabled?(:timelog_categories, quick_action_target.project)
            "#{base_params} <[timecategory:category-name]>"
          else
            base_params
          end
        end
        types Issue, MergeRequest
        condition do
          quick_action_target.supports_time_tracking? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        parse_params do |raw_time_date|
          Gitlab::QuickActions::SpendTimeAndDateSeparator.new(raw_time_date).execute
        end
        command :spend, :spent, :spend_time do |time_spent, time_spent_date, category|
          if time_spent
            @updates[:spend_time] = {
              duration: time_spent,
              user_id: current_user.id,
              spent_at: time_spent_date,
              category: category
            }
          end
        end

        ########################################################################
        #
        # /remind_me
        #
        types Issue, MergeRequest
        desc do
          _('Set to-do reminder')
        end
        explanation do
          _('Creates a reminder to-do item after the specified time period.')
        end
        params '<1w 3d 2h 14m>'
        parse_params do |raw_delay|
          ChronicDuration.parse(raw_delay)
        end
        condition do
          Feature.enabled?(:remind_me_quick_action, quick_action_target.project)
        end
        command :remind_me do |parsed_delay|
          # Schedule a CreateReminderWorker for the specified delay
          #
          ::Issuable::CreateReminderWorker.perform_in(
            parsed_delay,
            quick_action_target.id,
            quick_action_target.class.to_s,
            current_user.id
          )

          @execution_message[:remind_me] = _('Reminder set.')
        end

        ########################################################################
        #
        # /remove_estimate, /remove_time_estimate
        #
        desc { _('Remove time estimate') }
        explanation { _('Removes time estimate.') }
        execution_message { _('Removed time estimate.') }
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :remove_estimate, :remove_time_estimate do
          @updates[:time_estimate] = 0
        end

        ########################################################################
        #
        # /remove_time_spent
        #
        desc { _('Remove spent time') }
        explanation { _('Removes spent time.') }
        execution_message { _('Removed spent time.') }
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        types Issue, MergeRequest
        command :remove_time_spent do
          @updates[:spend_time] = { duration: :reset, user_id: current_user.id }
        end

        ########################################################################
        #
        # /lock
        #
        desc { _("Lock the discussion") }
        explanation { _("Locks the discussion.") }
        execution_message { _("Locked the discussion.") }
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            !quick_action_target.discussion_locked? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        command :lock do
          @updates[:discussion_locked] = true
        end

        ########################################################################
        #
        # /unlock
        #
        desc { _("Unlock the discussion") }
        explanation { _("Unlocks the discussion.") }
        execution_message { _("Unlocked the discussion.") }
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.discussion_locked? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        command :unlock do
          @updates[:discussion_locked] = false
        end

        private

        def assignee_users_sentence(users)
          if quick_action_target.allows_multiple_assignees?
            users
          else
            [users.first]
          end.map(&:to_reference).to_sentence
        end

        def assignees_for_removal(users)
          assignees = quick_action_target.assignees
          if users.present? && quick_action_target.allows_multiple_assignees?
            users
          else
            assignees
          end
        end

        def can_copy_metadata?(source_issuable)
          source_issuable.present? && find_namespace(source_issuable) == find_namespace(quick_action_target)
        end

        def find_namespace(item)
          case item
          # WorkItem check should be before Issue, as WorkItem is a subclass of Issue
          when WorkItem
            handle_namespace_type(item.namespace)
          when MergeRequest, Issue
            item.project
          end
        end

        def handle_namespace_type(namespace)
          case namespace
          when Project, Group
            namespace
          when Namespaces::ProjectNamespace
            namespace.project
          end
        end

        def format_time_estimate(time_estimate)
          Gitlab::TimeTrackingFormatter.output(time_estimate)
        end

        def spend_time_message(time_spent, time_spent_date, paste_tense)
          return unless time_spent

          if time_spent > 0
            verb = paste_tense ? _('Added') : _('Adds')
            value = time_spent
          else
            verb = paste_tense ? _('Subtracted') : _('Subtracts')
            value = -time_spent
          end

          _("%{verb} %{time_spent_value} spent time.") % { verb: verb, time_spent_value: format_time_estimate(value) }
        end
      end
    end
  end
end
