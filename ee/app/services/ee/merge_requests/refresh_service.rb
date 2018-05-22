module EE
  module MergeRequests
    module RefreshService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(oldrev, newrev, ref)
        return true unless ::Gitlab::Git.branch_ref?(ref)

        super && reset_approvals_for_merge_requests(ref, newrev)
      end

      private

      # Note: Closed merge requests also need approvals reset.
      def reset_approvals_for_merge_requests(ref, newrev)
        branch_name = ::Gitlab::Git.ref_name(ref)
        merge_requests = merge_requests_for(branch_name, mr_states: [:opened, :closed])

        merge_requests.each do |merge_request|
          target_project = merge_request.target_project

          if target_project.approvals_before_merge.nonzero? &&
              target_project.reset_approvals_on_push &&
              merge_request.rebase_commit_sha != newrev

            merge_request.approvals.delete_all
          end
        end
      end
    end
  end
end
