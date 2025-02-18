# frozen_string_literal: true

module Gitlab
  module QuickActions
    module MergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      REBASE_FAILURE_UNMERGEABLE = 'This merge request is currently in an unmergeable state, and cannot be rebased.'
      REBASE_FAILURE_PROTECTED_BRANCH = 'This merge request branch is protected from force push.'
      REBASE_FAILURE_REBASE_IN_PROGRESS = 'A rebase is already in progress.'

      included do
        # MergeRequest only quick actions definitions
        #

        ########################################################################
        #
        # /merge
        #
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
          if params[:merge_request_diff_head_sha].blank?
            _("The `/merge` quick action requires the SHA of the head of the branch.")
          elsif params[:merge_request_diff_head_sha] != quick_action_target.diff_head_sha
            _("Branch has been updated since the merge was requested.")
          elsif preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
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
          next unless params[:merge_request_diff_head_sha].present?

          next unless params[:merge_request_diff_head_sha] == quick_action_target.diff_head_sha

          @updates[:merge] = params[:merge_request_diff_head_sha]
        end

        ########################################################################
        #
        # /rebase
        #
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
          unless quick_action_target.permits_force_push?
            @execution_message[:rebase] = _(REBASE_FAILURE_PROTECTED_BRANCH)
            next
          end

          if quick_action_target.cannot_be_merged?
            @execution_message[:rebase] = _(REBASE_FAILURE_UNMERGEABLE)
            next
          end

          if quick_action_target.rebase_in_progress?
            @execution_message[:rebase] = _(REBASE_FAILURE_REBASE_IN_PROGRESS)
            next
          end

          # This will be used to avoid simultaneous "/merge" and "/rebase" actions
          @updates[:rebase] = true

          branch = quick_action_target.source_branch

          @execution_message[:rebase] = _('Scheduled a rebase of branch %{branch}.') % { branch: branch }
        end

        ########################################################################
        #
        # /draft
        #
        desc { _('Set the Draft status') }
        explanation do
          draft_action_message(_("Marks"))
        end
        execution_message do
          draft_action_message(_("Marked"))
        end

        types MergeRequest
        condition do
          quick_action_target.respond_to?(:draft?) &&
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :draft do
          @updates[:wip_event] = 'draft'
        end

        ########################################################################
        #
        # /ready
        #
        desc { _('Set the Ready status') }
        explanation do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.draft?
            _("Marks this %{noun} as ready.")
          else
            _("No change to this %{noun}'s draft status.")
          end % { noun: noun }
        end
        execution_message do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.draft?
            _("Marked this %{noun} as ready.")
          else
            _("No change to this %{noun}'s draft status.")
          end % { noun: noun }
        end

        types MergeRequest
        condition do
          # Allow it to mark as draft on MR creation page or through MR notes
          #
          quick_action_target.respond_to?(:draft?) &&
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :ready do
          @updates[:wip_event] = 'ready' if quick_action_target.draft?
        end

        ########################################################################
        #
        # /target_branch
        #
        desc { _('Set target branch') }
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

        ########################################################################
        #
        # /submit_review
        #
        desc { _('Submit a review') }
        explanation { _('Submit the current review.') }
        types MergeRequest
        condition do
          quick_action_target.persisted?
        end
        command :submit_review do |state = "reviewed"|
          next if params[:review_id]

          result = DraftNotes::PublishService.new(quick_action_target, current_user).execute

          reviewer_state = state.strip.presence

          @execution_message[:submit_review] = if result[:status] == :success
                                                 [_('Submitted the current review.')]
                                               else
                                                 [result[:message]]
                                               end

          if reviewer_state === 'approve'
            approval_success = ::MergeRequests::ApprovalService
              .new(project: quick_action_target.project, current_user: current_user)
              .execute(quick_action_target)

            @execution_message[:submit_review] << if approval_success
                                                    _('Approved the current merge request.')
                                                  else
                                                    _('Failed to approve the current merge request.')
                                                  end
          elsif MergeRequestReviewer.states.key?(reviewer_state)
            ::MergeRequests::UpdateReviewerStateService
              .new(project: quick_action_target.project, current_user: current_user)
              .execute(quick_action_target, reviewer_state)
          end
        end

        ########################################################################
        #
        # /request_changes
        #
        desc { _('Request changes') }
        explanation { _('Request changes to the current merge request.') }
        types MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.find_reviewer(current_user)
        end
        command :request_changes do
          result = ::MergeRequests::UpdateReviewerStateService.new(project: quick_action_target.project, current_user: current_user)
            .execute(quick_action_target, "requested_changes")

          @execution_message[:request_changes] = if result[:status] == :success
                                                   _('Changes requested to the current merge request.')
                                                 else
                                                   result[:message]
                                                 end
        end

        ########################################################################
        #
        # /approve
        #
        desc { _('Approve a merge request') }
        explanation { _('Approve the current merge request.') }
        types MergeRequest
        condition do
          quick_action_target.persisted? && quick_action_target.eligible_for_approval_by?(current_user) && !quick_action_target.merged?
        end
        command :approve do
          success = ::MergeRequests::ApprovalService.new(project: quick_action_target.project, current_user: current_user).execute(quick_action_target)

          next unless success

          @execution_message[:approve] = _('Approved the current merge request.')
        end

        ########################################################################
        #
        # /unapprove
        #
        desc { _('Unapprove a merge request') }
        explanation { _('Unapprove the current merge request.') }
        types MergeRequest
        condition do
          quick_action_target.persisted? && quick_action_target.eligible_for_unapproval_by?(current_user) && !quick_action_target.merged?
        end
        command :unapprove do
          success = ::MergeRequests::RemoveApprovalService.new(project: quick_action_target.project, current_user: current_user).execute(quick_action_target)

          next unless success

          @execution_message[:unapprove] = _('Unapproved the current merge request.')
        end

        ########################################################################
        #
        # /assign_reviewer
        #
        desc do
          if quick_action_target.allows_multiple_reviewers?
            _('Assign reviewers')
          else
            _('Assign reviewer')
          end
        end
        explanation do |users|
          reviewers = reviewers_to_add(users)
          if reviewers.blank?
            _("Failed to assign a reviewer because no user was specified.")
          else
            _('Assigns %{reviewer_users_sentence} as %{reviewer_text}.') % { reviewer_users_sentence: reviewer_users_sentence(users),
                                                                           reviewer_text: 'reviewer'.pluralize(reviewers.size) }
          end
        end
        execution_message do |users = nil|
          reviewers = reviewers_to_add(users)
          if reviewers.blank?
            _("Failed to assign a reviewer because no user was specified.")
          else
            _('Assigned %{reviewer_users_sentence} as %{reviewer_text}.') % { reviewer_users_sentence: reviewer_users_sentence(users),
                                                                              reviewer_text: 'reviewer'.pluralize(reviewers.size) }
          end
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : '@user'
        end
        types MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |reviewer_param|
          extract_users(reviewer_param)
        end
        command :assign_reviewer, :reviewer do |users|
          next if users.empty?

          if quick_action_target.allows_multiple_reviewers?
            @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)
            @updates[:reviewer_ids] |= users.map(&:id)
          else
            @updates[:reviewer_ids] = [users.first.id]
          end
        end

        ########################################################################
        #
        # /request_review
        #
        desc do
          _('Request a review')
        end
        explanation do |users|
          if users.blank?
            _("Failed to request a review because no user was specified.")
          else
            _('Requests a review from %{reviewer_users_sentence}.') % { reviewer_users_sentence: reviewer_users_sentence(users) }
          end
        end
        execution_message do |users = nil|
          if users.blank?
            _("Failed to request a review because no user was specified.")
          else
            _('Requested a review from %{reviewer_users_sentence}.') % { reviewer_users_sentence: reviewer_users_sentence(users) }
          end
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : '@user'
        end
        types MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |reviewer_param|
          extract_users(reviewer_param)
        end
        command :request_review do |users|
          next if users.empty?

          @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)

          service = ::MergeRequests::RequestReviewService.new(
            project: quick_action_target.project,
            current_user: current_user
          )

          reviewers_to_add(users).each do |user|
            if @updates[:reviewer_ids].include?(user.id)
              # Request a new review from the reviewer if they are already assigned
              service.execute(quick_action_target, user)
            else
              # Assign the user as a reviewer if they are not already
              @updates[:reviewer_ids] << user.id
            end
          end
        end

        ########################################################################
        #
        # /unassign_reviewer
        #
        desc do
          if quick_action_target.allows_multiple_reviewers?
            _('Remove all or specific reviewers')
          else
            _('Remove reviewer')
          end
        end
        explanation do |users = nil|
          reviewers = reviewers_for_removal(users)
          _("Removes %{reviewer_text} %{reviewer_references}.") %
            { reviewer_text: 'reviewer'.pluralize(reviewers.size), reviewer_references: reviewers.map(&:to_reference).to_sentence }
        end
        execution_message do |users = nil|
          reviewers = reviewers_for_removal(users)
          _("Removed %{reviewer_text} %{reviewer_references}.") %
            { reviewer_text: 'reviewer'.pluralize(reviewers.size), reviewer_references: reviewers.map(&:to_reference).to_sentence }
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : ''
        end
        types MergeRequest
        condition do
          reviewers_to_remove?(@updates) &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |unassign_reviewer_param|
          # When multiple users are assigned, all will be unassigned if multiple reviewers are no longer allowed
          extract_users(unassign_reviewer_param) if quick_action_target.allows_multiple_reviewers?
        end
        command :unassign_reviewer, :remove_reviewer do |users = nil|
          current_reviewers = quick_action_target.reviewers
          # if preceding commands have been executed already, we need to use the updated reviewer_ids
          current_reviewers = User.find(@updates[:reviewer_ids]) if @updates[:reviewer_ids].present?

          if quick_action_target.allows_multiple_reviewers? && users&.any?
            @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)
            @updates[:reviewer_ids] -= users.map(&:id)
          else
            @updates[:reviewer_ids] = []
          end

          removed_reviewers = current_reviewers.select { |user| @updates[:reviewer_ids].exclude?(user.id) }
          # only generate the message here if the change would not be traceable otherwise
          # because all reviewers have been assigned and removed immediately
          if removed_reviewers.present? && !reviewers_to_remove?(@updates)
            @execution_message[:unassign_reviewer] = _("Removed %{reviewer_text} %{reviewer_references}.") %
              { reviewer_text: 'reviewer'.pluralize(removed_reviewers.size), reviewer_references: removed_reviewers.map(&:to_reference).to_sentence }
          end
        end
      end

      def reviewer_users_sentence(users)
        reviewers_to_add(users).map(&:to_reference).to_sentence
      end

      def reviewers_for_removal(users)
        reviewers = quick_action_target.reviewers
        if users.present? && quick_action_target.allows_multiple_reviewers?
          users
        else
          reviewers
        end
      end

      def reviewers_to_add(users)
        return if users.blank?

        if quick_action_target.allows_multiple_reviewers?
          users
        else
          [users.first]
        end
      end

      def draft_action_message(verb)
        noun = quick_action_target.to_ability_name.humanize(capitalize: false)
        if !quick_action_target.draft?
          _("%{verb} this %{noun} as a draft.")
        else
          _("No change to this %{noun}'s draft status.")
        end % { verb: verb, noun: noun }
      end

      def reviewers_to_remove?(updates)
        quick_action_target.reviewers.any? || updates&.dig(:reviewer_ids)&.any?
      end

      def merge_orchestration_service
        @merge_orchestration_service ||= ::MergeRequests::MergeOrchestrationService.new(project, current_user)
      end

      def preferred_auto_merge_strategy(merge_request)
        merge_orchestration_service.preferred_auto_merge_strategy(merge_request)
      end
    end
  end
end
