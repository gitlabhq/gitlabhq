# frozen_string_literal: true

module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class MergeService < MergeRequests::MergeBaseService
    include Gitlab::Utils::StrongMemoize

    GENERIC_ERROR_MESSAGE = 'An error occurred while merging'

    delegate :merge_jid, :state, to: :@merge_request

    def execute(merge_request, options = {})
      return if merge_request.merged?
      return unless exclusive_lease(merge_request).try_obtain

      merge_strategy_class = options[:merge_strategy] || MergeRequests::MergeStrategies::FromSourceBranch
      @merge_strategy = merge_strategy_class.new(merge_request, current_user, merge_params: params, options: options)

      @merge_request = merge_request
      @options = options
      jid = merge_jid

      validate!

      merge_request.in_locked_state do
        if commit
          after_merge
          success
        end
      end

      log_info("Merge process finished on JID #{jid} with state #{state}")
    rescue MergeError, MergeRequests::MergeStrategies::StrategyError => e
      handle_merge_error(log_message: e.message, save_message_on_model: true)
    ensure
      exclusive_lease(merge_request).cancel
    end

    private

    def validate!
      authorization_check!
      error_check!
      validate_strategy!
      updated_check!
    end

    def authorization_check!
      unless @merge_request.can_be_merged_by?(current_user)
        raise_error('You are not allowed to merge this merge request')
      end
    end

    def validate_strategy!
      @merge_strategy.validate!
    end

    def updated_check!
      unless source_matches?
        raise_error('Branch has been updated since the merge was requested. '\
                    'Please review the changes.')
      end
    end

    def commit
      log_info("Git merge started on JID #{merge_jid}")

      merge_result = try_merge { @merge_strategy.execute_git_merge! }

      commit_sha = merge_result[:commit_sha]
      raise_error(GENERIC_ERROR_MESSAGE) unless commit_sha

      log_info("Git merge finished on JID #{merge_jid} commit #{commit_sha}")

      new_merge_request_attributes = {
        merged_commit_sha: commit_sha,
        merge_commit_sha: merge_result[:merge_commit_sha],
        squash_commit_sha: merge_result[:squash_commit_sha]
      }.compact
      merge_request.update!(new_merge_request_attributes) if new_merge_request_attributes.present?

      commit_sha
    ensure
      merge_request.update_and_mark_in_progress_merge_commit_sha(nil)
      log_info("Merge request marked in progress")
    end

    def try_merge
      yield
    rescue Gitlab::Git::PreReceiveError => e
      raise MergeError, "Something went wrong during merge pre-receive hook. #{e.message}".strip
    rescue StandardError => e
      handle_merge_error(log_message: e.message)
      raise_error(GENERIC_ERROR_MESSAGE)
    end

    def after_merge
      # Need to store `merge_jid` in a variable since `MergeRequests::PostMergeService`
      # will call `MergeRequest#mark_as_merged` and will unset `merge_jid`.
      jid = merge_jid

      log_info("Post merge started on JID #{jid} with state #{state}")
      MergeRequests::PostMergeService.new(project: project, current_user: current_user, params: { delete_source_branch:
                                          delete_source_branch? }).execute(merge_request)
      log_info("Post merge finished on JID #{jid} with state #{state}")

      if delete_source_branch?
        MergeRequests::DeleteSourceBranchWorker.perform_async(@merge_request.id, @merge_request.source_branch_sha, branch_deletion_user.id)
      end

      merge_request_merge_param
    end

    def branch_deletion_user
      current_user
    end

    # Verify again that the source branch can be removed, since branch may be protected,
    # or the source branch may have been updated, or the user may not have permission
    #
    def delete_source_branch?
      params.fetch('should_remove_source_branch', @merge_request.force_remove_source_branch?) &&
        @merge_request.can_remove_source_branch?(branch_deletion_user)
    end

    def merge_request_merge_param
      if @merge_request.can_remove_source_branch?(branch_deletion_user) && !params.fetch('should_remove_source_branch', nil).nil?
        @merge_request.update(merge_params: @merge_request.merge_params.merge('should_remove_source_branch' => params['should_remove_source_branch']))
      end
    end

    def handle_merge_error(log_message:, save_message_on_model: false)
      log_error("MergeService ERROR: #{merge_request_info}:#{merge_status} - #{log_message}")
      @merge_request.update(merge_error: log_message) if save_message_on_model
    end

    def log_info(message)
      payload = log_payload("#{merge_request_info} - #{message}")
      logger.info(**payload)
    end

    def log_error(message)
      payload = log_payload(message)
      logger.error(**payload)
    end

    def logger
      @logger ||= Gitlab::AppLogger
    end

    def log_payload(message)
      Gitlab::ApplicationContext.current.merge(merge_request_info: merge_request_info, message: message)
    end

    def merge_request_info
      @merge_request_info ||= merge_request.to_reference(full: true)
    end

    def merge_status
      @merge_status ||= @merge_request.merge_status
    end

    def source_matches?
      # params-keys are symbols coming from the controller, but when they get
      # loaded from the database they're strings
      params.with_indifferent_access[:sha] == merge_request.diff_head_sha
    end

    def exclusive_lease(merge_request)
      strong_memoize(:"exclusive_lease_#{merge_request.id}") do
        merge_request.merge_exclusive_lease
      end
    end
  end
end

MergeRequests::MergeService.prepend_mod
