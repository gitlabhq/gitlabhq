# frozen_string_literal: true

module Gitlab
  module QuickActions
    module IssueAndMergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # Issue, MergeRequest: quick actions definitions
        desc 'Assign'
        # rubocop: disable CodeReuse/ActiveRecord
        explanation do |users|
          users = quick_action_target.allows_multiple_assignees? ? users : users.take(1)
          "Assigns #{users.map(&:to_reference).to_sentence}."
        end
        # rubocop: enable CodeReuse/ActiveRecord
        params do
          quick_action_target.allows_multiple_assignees? ? '@user1 @user2' : '@user'
        end
        types Issue, MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |assignee_param|
          extract_users(assignee_param)
        end
        command :assign do |users|
          next if users.empty?

          if quick_action_target.allows_multiple_assignees?
            @updates[:assignee_ids] ||= quick_action_target.assignees.map(&:id)
            @updates[:assignee_ids] += users.map(&:id)
          else
            @updates[:assignee_ids] = [users.first.id]
          end
        end

        desc do
          if quick_action_target.allows_multiple_assignees?
            'Remove all or specific assignee(s)'
          else
            'Remove assignee'
          end
        end
        explanation do |users = nil|
          assignees = quick_action_target.assignees
          assignees &= users if users.present? && quick_action_target.allows_multiple_assignees?
          "Removes #{'assignee'.pluralize(assignees.size)} #{assignees.map(&:to_reference).to_sentence}."
        end
        params do
          quick_action_target.allows_multiple_assignees? ? '@user1 @user2' : ''
        end
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.assignees.any? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
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

        desc 'Set milestone'
        explanation do |milestone|
          "Sets the milestone to #{milestone.to_reference}." if milestone
        end
        params '%"milestone"'
        types Issue, MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project) &&
            find_milestones(project, state: 'active').any?
        end
        parse_params do |milestone_param|
          extract_references(milestone_param, :milestone).first ||
            find_milestones(project, title: milestone_param.strip).first
        end
        command :milestone do |milestone|
          @updates[:milestone_id] = milestone.id if milestone
        end

        desc 'Remove milestone'
        explanation do
          "Removes #{quick_action_target.milestone.to_reference(format: :name)} milestone."
        end
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.milestone_id? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        command :remove_milestone do
          @updates[:milestone_id] = nil
        end

        desc 'Copy labels and milestone from other issue or merge request'
        explanation do |source_issuable|
          "Copy labels and milestone from #{source_issuable.to_reference}."
        end
        params '#issue | !merge_request'
        types Issue, MergeRequest
        condition do
          current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        parse_params do |issuable_param|
          extract_references(issuable_param, :issue).first ||
            extract_references(issuable_param, :merge_request).first
        end
        command :copy_metadata do |source_issuable|
          if source_issuable.present? && source_issuable.project.id == quick_action_target.project.id
            @updates[:add_label_ids] = source_issuable.labels.map(&:id)
            @updates[:milestone_id] = source_issuable.milestone.id if source_issuable.milestone
          end
        end

        desc 'Set time estimate'
        explanation do |time_estimate|
          time_estimate = Gitlab::TimeTrackingFormatter.output(time_estimate)

          "Sets time estimate to #{time_estimate}." if time_estimate
        end
        params '<1w 3d 2h 14m>'
        types Issue, MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |raw_duration|
          Gitlab::TimeTrackingFormatter.parse(raw_duration)
        end
        command :estimate do |time_estimate|
          if time_estimate
            @updates[:time_estimate] = time_estimate
          end
        end

        desc 'Add or subtract spent time'
        explanation do |time_spent, time_spent_date|
          if time_spent
            if time_spent > 0
              verb = 'Adds'
              value = time_spent
            else
              verb = 'Subtracts'
              value = -time_spent
            end

            "#{verb} #{Gitlab::TimeTrackingFormatter.output(value)} spent time."
          end
        end
        params '<time(1h30m | -1h30m)> <date(YYYY-MM-DD)>'
        types Issue, MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        parse_params do |raw_time_date|
          Gitlab::QuickActions::SpendTimeAndDateSeparator.new(raw_time_date).execute
        end
        command :spend do |time_spent, time_spent_date|
          if time_spent
            @updates[:spend_time] = {
              duration: time_spent,
              user_id: current_user.id,
              spent_at: time_spent_date
            }
          end
        end

        desc 'Remove time estimate'
        explanation 'Removes time estimate.'
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        command :remove_estimate do
          @updates[:time_estimate] = 0
        end

        desc 'Remove spent time'
        explanation 'Removes spent time.'
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        types Issue, MergeRequest
        command :remove_time_spent do
          @updates[:spend_time] = { duration: :reset, user_id: current_user.id }
        end

        desc "Lock the discussion"
        explanation "Locks the discussion"
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            !quick_action_target.discussion_locked? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :lock do
          @updates[:discussion_locked] = true
        end

        desc "Unlock the discussion"
        explanation "Unlocks the discussion"
        types Issue, MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.discussion_locked? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :unlock do
          @updates[:discussion_locked] = false
        end
      end
    end
  end
end
