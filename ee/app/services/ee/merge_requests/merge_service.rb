module EE
  module MergeRequests
    module MergeService
      extend ::Gitlab::Utils::Override

      override :error_check!
      def error_check!
        check_size_limit

        super
      end

      def source
        return merge_request.diff_head_sha unless merge_request.squash

        squash_result = ::MergeRequests::SquashService.new(project, current_user, params).execute(merge_request)

        case squash_result[:status]
        when :success
          squash_result[:squash_sha]
        when :error
          raise ::MergeRequests::MergeService::MergeError, squash_result[:message]
        end
      end

      private

      def check_size_limit
        if merge_request.target_project.above_size_limit?
          message = ::Gitlab::RepositorySizeError.new(merge_request.target_project).merge_error

          raise ::MergeRequests::MergeService::MergeError, message
        end
      end
    end
  end
end
