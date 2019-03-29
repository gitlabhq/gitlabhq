# frozen_string_literal: true

module Gitlab
  module QuickActions
    module MergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # MergeRequest only quick actions definitions
        desc 'Merge (when the pipeline succeeds)'
        explanation 'Merges this merge request when the pipeline succeeds.'
        types MergeRequest
        condition do
          last_diff_sha = params && params[:merge_request_diff_head_sha]
          quick_action_target.persisted? &&
            quick_action_target.mergeable_with_quick_action?(current_user, autocomplete_precheck: !last_diff_sha, last_diff_sha: last_diff_sha)
        end
        command :merge do
          @updates[:merge] = params[:merge_request_diff_head_sha]
        end

        desc 'Toggle the Work In Progress status'
        explanation do
          verb = quick_action_target.work_in_progress? ? 'Unmarks' : 'Marks'
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          "#{verb} this #{noun} as Work In Progress."
        end
        types MergeRequest
        condition do
          quick_action_target.respond_to?(:work_in_progress?) &&
            # Allow it to mark as WIP on MR creation page _or_ through MR notes.
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :wip do
          @updates[:wip_event] = quick_action_target.work_in_progress? ? 'unwip' : 'wip'
        end

        desc 'Set target branch'
        explanation do |branch_name|
          "Sets target branch to #{branch_name}."
        end
        params '<Local branch name>'
        types MergeRequest
        condition do
          quick_action_target.respond_to?(:target_branch) &&
            (current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target) ||
              quick_action_target.new_record?)
        end
        parse_params do |target_branch_param|
          target_branch_param.strip
        end
        command :target_branch do |branch_name|
          @updates[:target_branch] = branch_name if project.repository.branch_exists?(branch_name)
        end
      end
    end
  end
end
