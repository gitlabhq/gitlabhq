# frozen_string_literal: true

module Gitlab
  module QuickActions
    module IssueActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # Issue only quick actions definition
        desc 'Set due date'
        explanation do |due_date|
          "Sets the due date to #{due_date.to_s(:medium)}." if due_date
        end
        params '<in 2 days | this Friday | December 31st>'
        types Issue
        condition do
          quick_action_target.respond_to?(:due_date) &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |due_date_param|
          Chronic.parse(due_date_param).try(:to_date)
        end
        command :due do |due_date|
          @updates[:due_date] = due_date if due_date
        end

        desc 'Remove due date'
        explanation 'Removes the due date.'
        types Issue
        condition do
          quick_action_target.persisted? &&
            quick_action_target.respond_to?(:due_date) &&
            quick_action_target.due_date? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        command :remove_due_date do
          @updates[:due_date] = nil
        end

        desc 'Move issue from one column of the board to another'
        explanation do |target_list_name|
          label = find_label_references(target_list_name).first
          "Moves issue to #{label} column in the board." if label
        end
        params '~"Target column"'
        types Issue
        condition do
          current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target) &&
            quick_action_target.project.boards.count == 1
        end
        # rubocop: disable CodeReuse/ActiveRecord
        command :board_move do |target_list_name|
          label_ids = find_label_ids(target_list_name)

          if label_ids.size == 1
            label_id = label_ids.first

            # Ensure this label corresponds to a list on the board
            next unless Label.on_project_boards(quick_action_target.project_id).where(id: label_id).exists?

            @updates[:remove_label_ids] =
              quick_action_target.labels.on_project_boards(quick_action_target.project_id).where.not(id: label_id).pluck(:id)
            @updates[:add_label_ids] = [label_id]
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Mark this issue as a duplicate of another issue'
        explanation do |duplicate_reference|
          "Marks this issue as a duplicate of #{duplicate_reference}."
        end
        params '#issue'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :duplicate do |duplicate_param|
          canonical_issue = extract_references(duplicate_param, :issue).first

          if canonical_issue.present?
            @updates[:canonical_issue_id] = canonical_issue.id
          end
        end

        desc 'Move this issue to another project.'
        explanation do |path_to_project|
          "Moves this issue to #{path_to_project}."
        end
        params 'path/to/project'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        command :move do |target_project_path|
          target_project = Project.find_by_full_path(target_project_path)

          if target_project.present?
            @updates[:target_project] = target_project
          end
        end

        desc 'Make issue confidential.'
        explanation do
          'Makes this issue confidential'
        end
        types Issue
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :confidential do
          @updates[:confidential] = true
        end

        desc 'Create a merge request.'
        explanation do |branch_name = nil|
          branch_text = branch_name ? "branch '#{branch_name}'" : 'a branch'
          "Creates #{branch_text} and a merge request to resolve this issue"
        end
        params "<branch name>"
        types Issue
        condition do
          current_user.can?(:create_merge_request_in, project) && current_user.can?(:push_code, project)
        end
        command :create_merge_request do |branch_name = nil|
          @updates[:create_merge_request] = {
            branch_name: branch_name,
            issue_iid: quick_action_target.iid
          }
        end
      end
    end
  end
end
