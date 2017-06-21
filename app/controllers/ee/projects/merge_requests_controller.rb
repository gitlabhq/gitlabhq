module EE
  module Projects
    module MergeRequestsController
      extend ActiveSupport::Concern

      prepended do
        # This module is prepended to `Projects::MergeRequestController`, which
        # already calls `before_action :merge_request, only: [...]`. Calling it
        # again here would *replace* the restriction, rather than extending it.
        before_action(only: [:approve, :approvals, :unapprove, :rebase]) { merge_request }

        before_action :set_suggested_approvers, only: [:new, :new_diffs, :edit]
        before_action :check_merge_request_rebase_available!, only: [:rebase]
      end

      def rebase
        return access_denied! unless @merge_request.can_be_merged_by?(current_user)
        return render_404 unless @merge_request.approved?

        RebaseWorker.perform_async(@merge_request.id, current_user.id)

        render nothing: true, status: 200
      end

      def approve
        unless @merge_request.can_approve?(current_user)
          return render_404
        end

        ::MergeRequests::ApprovalService
          .new(project, current_user)
          .execute(@merge_request)

        render_approvals_json
      end

      def approvals
        render_approvals_json
      end

      def unapprove
        if @merge_request.has_approved?(current_user)
          ::MergeRequests::RemoveApprovalService
            .new(project, current_user)
            .execute(@merge_request)
        end

        render_approvals_json
      end

      protected

      def render_approvals_json
        respond_to do |format|
          format.json do
            entity = ::API::Entities::MergeRequestApprovals.new(@merge_request, current_user: current_user)
            render json: entity
          end
        end
      end

      def set_suggested_approvers
        if @merge_request.requires_approve?
          @suggested_approvers = ::Gitlab::AuthorityAnalyzer.new(
            @merge_request,
            @merge_request.author || current_user
          ).calculate(@merge_request.approvals_required)
        end
      end

      def merge_params_attributes
        super + [:squash]
      end

      def merge_request_params
        clamp_approvals_before_merge(super)
      end

      def merge_request_params_attributes
        super + %i[
          approvals_before_merge
          approver_group_ids
          approver_ids
          squash
        ]
      end

      # If the number of approvals is not greater than the project default, set to
      # nil, so that we fall back to the project default. If it's not set, we can
      # let the normal update logic handle this.
      def clamp_approvals_before_merge(mr_params)
        return mr_params unless mr_params[:approvals_before_merge]

        target_project = @project.forked_from_project if @project.id.to_s != mr_params[:target_project_id]
        target_project ||= @project

        if mr_params[:approvals_before_merge].to_i <= target_project.approvals_before_merge
          mr_params[:approvals_before_merge] = nil
        end

        mr_params
      end
    end
  end
end
