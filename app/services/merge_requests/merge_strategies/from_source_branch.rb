# frozen_string_literal: true

module MergeRequests
  module MergeStrategies
    # FromSourceBranch performs a git merge from a merge request's source branch
    # to the target branch, including a squash if needed.
    class FromSourceBranch
      include Gitlab::Utils::StrongMemoize

      delegate :repository, to: :project

      def initialize(merge_request, current_user, merge_params: {}, options: {})
        @merge_request = merge_request
        @current_user = current_user
        @project = merge_request.project
        @merge_params = merge_params
        @options = options
      end

      def validate!
        if use_create_ref_service?
          raise_error('No source for merge') if merge_request.diff_head_sha.blank?
        else
          raise_error('No source for merge') if source_sha.blank?

          if merge_request.should_be_rebased?
            raise_error('Only fast-forward merge is allowed for your project. Please update your source branch')
          end
        end

        raise_error('Merge request is not mergeable') unless mergeable?

        return unless merge_request.missing_required_squash?

        raise_error('This project requires squashing commits when merge requests are accepted.')
      end

      def execute_git_merge!
        if use_create_ref_service?
          create_ref_result = MergeRequests::CreateRefService.new(
            current_user: current_user,
            merge_request: merge_request,
            source_sha: merge_request.diff_head_sha,
            target_ref: merge_request.rebase_on_merge_path,
            first_parent_ref: merge_request.target_branch_ref
          ).execute

          payload = create_ref_result.payload

          src_sha = payload[:commit_sha]

          payload[:commit_sha] = fast_forward!(src_sha)[:commit_sha]

          merge_request.schedule_cleanup_refs(only: [:rebase_on_merge_path])

          log_info("Used new from source branch merge")

          payload
        else
          result = if project.merge_requests_ff_only_enabled
                     fast_forward!(source_sha)
                   else
                     merge_commit!
                   end

          result[:squash_commit_sha] = source_sha if merge_request.squash_on_merge?

          result
        end
      end

      private

      attr_reader :merge_request, :current_user, :merge_params, :options, :project

      # We only want to use the service when we can not directly fast_forward
      # and when ff merge must be possible
      def use_create_ref_service?
        Feature.enabled?(:rebase_on_merge_automatic, project) &&
          project.ff_merge_must_be_possible? &&
          merge_request.should_be_rebased?
      end
      strong_memoize_attr :use_create_ref_service?

      def source_sha
        if merge_request.squash_on_merge?
          squash_sha!
        else
          merge_request.diff_head_sha
        end
      end
      strong_memoize_attr :source_sha

      def squash_sha!
        squash_result = ::MergeRequests::SquashService
          .new(
            merge_request: merge_request,
            current_user: current_user,
            commit_message: merge_params[:squash_commit_message]
          ).execute

        case squash_result[:status]
        when :success
          squash_result[:squash_sha]
        when :error
          raise_error(squash_result[:message])
        end
      end

      def fast_forward!(src_sha)
        commit_sha = repository.ff_merge(
          current_user,
          src_sha,
          merge_request.target_branch,
          merge_request: merge_request
        )

        { commit_sha: commit_sha }
      end

      def merge_commit!
        commit_sha = repository.merge(
          current_user,
          source_sha,
          merge_request,
          merge_commit_message
        )

        { commit_sha: commit_sha, merge_commit_sha: commit_sha }
      end

      def merge_commit_message
        merge_params[:commit_message] ||
          merge_request.default_merge_commit_message(user: current_user)
      end

      def mergeable?
        merge_request.mergeable?(
          skip_discussions_check: options[:skip_discussions_check],
          check_mergeability_retry_lease: options[:check_mergeability_retry_lease]
        )
      end

      def raise_error(message)
        raise ::MergeRequests::MergeStrategies::StrategyError, message
      end

      def logger
        @logger ||= Gitlab::AppLogger
      end

      def log_payload(message)
        Gitlab::ApplicationContext.current.merge(merge_request_info: merge_request_info, message: message)
      end

      def log_info(message)
        payload = log_payload(message)
        logger.info(**payload)
      end

      def merge_request_info
        @merge_request_info ||= merge_request.to_reference(full: true)
      end
    end
  end
end

::MergeRequests::MergeStrategies::FromSourceBranch.prepend_mod
