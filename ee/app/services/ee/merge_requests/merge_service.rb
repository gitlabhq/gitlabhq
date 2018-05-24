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

      def hooks_validation_pass?(merge_request)
        # handle_merge_error needs this. We should move that to a separate
        # object instead of relying on the order of method calls.
        @merge_request = merge_request # rubocop:disable Gitlab/ModuleWithInstanceVariables

        return true if project.merge_requests_ff_only_enabled
        return true unless project.feature_available?(:push_rules)

        push_rule = merge_request.project.push_rule
        return true unless push_rule

        unless push_rule.commit_message_allowed?(params[:commit_message])
          handle_merge_error(log_message: "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'", save_message_on_model: true)
          return false
        end

        unless push_rule.author_email_allowed?(current_user.email)
          handle_merge_error(log_message: "Commit author's email '#{current_user.email}' does not follow the pattern '#{push_rule.author_email_regex}'", save_message_on_model: true)
          return false
        end

        true
      rescue PushRule::MatchError => e
        handle_merge_error(log_message: e.message, save_message_on_model: true)
        false
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
