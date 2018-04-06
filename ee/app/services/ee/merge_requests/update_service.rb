module EE
  module MergeRequests
    module UpdateService
      extend ::Gitlab::Utils::Override

      include CleanupApprovers

      override :execute
      def execute(merge_request)
        should_remove_old_approvers = params.delete(:remove_old_approvers)

        merge_request = super(merge_request)

        cleanup_approvers(merge_request, reload: true) if should_remove_old_approvers && merge_request.valid?

        merge_request
      end
    end
  end
end
