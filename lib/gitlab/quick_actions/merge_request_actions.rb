# frozen_string_literal: true

module Gitlab
  module QuickActions
    module MergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # MergeRequest only quick actions definitions
        desc do
          if Feature.enabled?(:merge_orchestration_service, quick_action_target.project, default_enabled: true)
            if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
              _("Merge automatically (%{strategy})") % { strategy: preferred_strategy.humanize }
            else
              _("Merge immediately")
            end
          else
            _('Merge (when the pipeline succeeds)')
          end
        end
        explanation do
          if Feature.enabled?(:merge_orchestration_service, quick_action_target.project, default_enabled: true)
            if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
              _("Schedules to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
            else
              _('Merges this merge request immediately.')
            end
          else
            _('Merges this merge request when the pipeline succeeds.')
          end
        end
        execution_message do
          if Feature.enabled?(:merge_orchestration_service, quick_action_target.project, default_enabled: true)
            if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
              _("Scheduled to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
            else
              _('Merged this merge request.')
            end
          else
            _('Scheduled to merge this merge request when the pipeline succeeds.')
          end
        end
        types MergeRequest
        condition do
          if Feature.enabled?(:merge_orchestration_service, quick_action_target.project, default_enabled: true)
            quick_action_target.persisted? &&
              merge_orchestration_service.can_merge?(quick_action_target)
          else
            last_diff_sha = params && params[:merge_request_diff_head_sha]
            quick_action_target.persisted? &&
              quick_action_target.mergeable_with_quick_action?(current_user, autocomplete_precheck: !last_diff_sha, last_diff_sha: last_diff_sha)
          end
        end
        command :merge do
          @updates[:merge] = params[:merge_request_diff_head_sha]
        end

        desc 'Toggle the Work In Progress status'
        explanation do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.work_in_progress?
            _("Unmarks this %{noun} as Work In Progress.")
          else
            _("Marks this %{noun} as Work In Progress.")
          end % { noun: noun }
        end
        execution_message do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.work_in_progress?
            _("Unmarked this %{noun} as Work In Progress.")
          else
            _("Marked this %{noun} as Work In Progress.")
          end % { noun: noun }
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

        desc _('Set target branch')
        explanation do |branch_name|
          _('Sets target branch to %{branch_name}.') % { branch_name: branch_name }
        end
        execution_message do |branch_name|
          _('Set target branch to %{branch_name}.') % { branch_name: branch_name }
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

      def merge_orchestration_service
        @merge_orchestration_service ||= MergeRequests::MergeOrchestrationService.new(project, current_user)
      end

      def preferred_auto_merge_strategy(merge_request)
        merge_orchestration_service.preferred_auto_merge_strategy(merge_request)
      end
    end
  end
end
