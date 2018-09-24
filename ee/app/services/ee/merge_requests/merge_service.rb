module EE
  module MergeRequests
    module MergeService
      extend ::Gitlab::Utils::Override

      override :error_check!
      def error_check!
        check_size_limit

        super
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

        if push_rule.commit_message_blocked?(params[:commit_message])
          handle_merge_error(log_message: "Commit message contains the forbidden pattern '#{push_rule.commit_message_negative_regex}'", save_message_on_model: true)
          return false
        end

        unless push_rule.author_email_allowed?(current_user.commit_email)
          handle_merge_error(log_message: "Commit author's email '#{current_user.commit_email}' does not follow the pattern '#{push_rule.author_email_regex}'", save_message_on_model: true)
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
