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
        raise_error('No source for merge') if source_sha.blank?

        if merge_request.should_be_rebased?
          raise_error('Only fast-forward merge is allowed for your project. Please update your source branch')
        end

        raise_error('Merge request is not mergeable') unless mergeable?

        return unless merge_request.missing_required_squash?

        raise_error('This project requires squashing commits when merge requests are accepted.')
      end

      def execute_git_merge!
        result =
          if project.merge_requests_ff_only_enabled
            fast_forward!
          else
            merge_commit!
          end

        result[:squash_commit_sha] = source_sha if merge_request.squash_on_merge?

        result
      end

      private

      attr_reader :merge_request, :current_user, :merge_params, :options, :project

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

      def fast_forward!
        commit_sha = repository.ff_merge(
          current_user,
          source_sha,
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
    end
  end
end

::MergeRequests::MergeStrategies::FromSourceBranch.prepend_mod
