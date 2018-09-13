module EE
  module Projects
    module MergeRequestsController
      extend ActiveSupport::Concern

      APPROVAL_RENDERING_ACTIONS = [:approve, :approvals, :unapprove].freeze

      def approve
        unless merge_request.can_approve?(current_user)
          return render_404
        end

        ::MergeRequests::ApprovalService
          .new(project, current_user)
          .execute(merge_request)

        render_approvals_json
      end

      def approvals
        render_approvals_json
      end

      def unapprove
        if merge_request.has_approved?(current_user)
          ::MergeRequests::RemoveApprovalService
            .new(project, current_user)
            .execute(merge_request)
        end

        render_approvals_json
      end

      protected

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      # Assigning both @merge_request and @issuable like in
      # `Projects::MergeRequests::ApplicationController`, and calling super if
      # we don't need the extra includes requires us to disable this cop.
      # rubocop: disable CodeReuse/ActiveRecord
      def merge_request
        return super unless APPROVAL_RENDERING_ACTIONS.include?(action_name.to_sym)

        @issuable = @merge_request ||= project.merge_requests
                                         .includes(
                                           :approved_by_users,
                                           approvers: :user
                                         )
                                         .find_by!(iid: params[:id])
        super
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def define_edit_vars
        super

        set_suggested_approvers
      end

      def render_approvals_json
        respond_to do |format|
          format.json do
            entity = EE::API::Entities::MergeRequestApprovals.new(merge_request, current_user: current_user)
            render json: entity
          end
        end
      end
    end
  end
end
