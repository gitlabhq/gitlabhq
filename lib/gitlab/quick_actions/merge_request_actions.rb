# frozen_string_literal: true

module Gitlab
  module QuickActions
    module MergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # MergeRequest only quick actions definitions
        desc do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Merge automatically (%{strategy})") % { strategy: preferred_strategy.humanize }
          else
            _("Merge immediately")
          end
        end
        explanation do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Schedules to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
          else
            _('Merges this merge request immediately.')
          end
        end
        execution_message do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Scheduled to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
          else
            _('Merged this merge request.')
          end
        end
        types MergeRequest
        condition do
          quick_action_target.persisted? &&
            merge_orchestration_service.can_merge?(quick_action_target)
        end
        command :merge do
          @updates[:merge] = params[:merge_request_diff_head_sha]
        end

        types MergeRequest
        desc do
          _('Rebase source branch')
        end
        explanation do
          _('Rebase source branch on the target branch.')
        end
        condition do
          merge_request = quick_action_target

          next false unless merge_request.open?
          next false unless merge_request.source_branch_exists?

          access_check = ::Gitlab::UserAccess
                           .new(current_user, container: merge_request.source_project)

          access_check.can_push_to_branch?(merge_request.source_branch)
        end
        command :rebase do
          if quick_action_target.rebase_in_progress?
            @execution_message[:rebase] = _('A rebase is already in progress.')
            next
          end

          # This will be used to avoid simultaneous "/merge" and "/rebase" actions
          @updates[:rebase] = true

          branch = quick_action_target.source_branch

          @execution_message[:rebase] = _('Scheduled a rebase of branch %{branch}.') % { branch: branch }
        end

        desc 'Toggle the Draft status'
        explanation do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.work_in_progress?
            _("Unmarks this %{noun} as a draft.")
          else
            _("Marks this %{noun} as a draft.")
          end % { noun: noun }
        end
        execution_message do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.work_in_progress?
            _("Unmarked this %{noun} as a draft.")
          else
            _("Marked this %{noun} as a draft.")
          end % { noun: noun }
        end

        types MergeRequest
        condition do
          quick_action_target.respond_to?(:work_in_progress?) &&
            # Allow it to mark as WIP on MR creation page _or_ through MR notes.
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :draft, :wip do
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

        desc _('Submit a review')
        explanation _('Submit the current review.')
        types MergeRequest
        condition do
          quick_action_target.persisted?
        end
        command :submit_review do
          next if params[:review_id]

          result = DraftNotes::PublishService.new(quick_action_target, current_user).execute
          @execution_message[:submit_review] = if result[:status] == :success
                                                 _('Submitted the current review.')
                                               else
                                                 result[:message]
                                               end
        end

        desc _('Approve a merge request')
        explanation _('Approve the current merge request.')
        types MergeRequest
        condition do
          quick_action_target.persisted? && quick_action_target.can_be_approved_by?(current_user)
        end
        command :approve do
          success = MergeRequests::ApprovalService.new(quick_action_target.project, current_user).execute(quick_action_target)

          next unless success

          @execution_message[:approve] = _('Approved the current merge request.')
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
