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
    LEASE_TIMEOUT = 15.minutes.to_i

    delegate :merge_jid, :state, to: :@merge_request

    def execute(merge_request, options = {})
      if project.merge_requests_ff_only_enabled && !self.is_a?(FfMergeService)
        FfMergeService.new(project: project, current_user: current_user, params: params).execute(merge_request)
        return
      end

      return if merge_request.merged?
      return unless exclusive_lease(merge_request.id).try_obtain

      @merge_request = merge_request
      @options = options

      validate!

      merge_request.in_locked_state do
        if commit
          after_merge
          clean_merge_jid
          success
        end
      end

      log_info("Merge process finished on JID #{merge_jid} with state #{state}")
    rescue MergeError => e
      handle_merge_error(log_message: e.message, save_message_on_model: true)
    ensure
      exclusive_lease(merge_request.id).cancel
    end

    private

    def validate!
      authorization_check!
      error_check!
      updated_check!
    end

    def authorization_check!
      unless @merge_request.can_be_merged_by?(current_user)
        raise_error('You are not allowed to merge this merge request')
      end
    end

    def error_check!
      super

      check_source

      error =
        if @merge_request.should_be_rebased?
          'Only fast-forward merge is allowed for your project. Please update your source branch'
        elsif !@merge_request.mergeable?(skip_discussions_check: @options[:skip_discussions_check])
          'Merge request is not mergeable'
        elsif !@merge_request.squash && project.squash_always?
          'This project requires squashing commits when merge requests are accepted.'
        end

      raise_error(error) if error
    end

    def updated_check!
      unless source_matches?
        raise_error('Branch has been updated since the merge was requested. '\
                    'Please review the changes.')
      end
    end

    def commit
      log_info("Git merge started on JID #{merge_jid}")
      commit_id = try_merge

      if commit_id
        log_info("Git merge finished on JID #{merge_jid} commit #{commit_id}")
      else
        raise_error(GENERIC_ERROR_MESSAGE)
      end

      merge_request.update!(merge_commit_sha: commit_id)
    ensure
      merge_request.update_and_mark_in_progress_merge_commit_sha(nil)
    end

    def try_merge
      repository.merge(current_user, source, merge_request, commit_message).tap do
        merge_request.update_column(:squash_commit_sha, source) if merge_request.squash_on_merge?
      end
    rescue Gitlab::Git::PreReceiveError => e
      raise MergeError,
            "Something went wrong during merge pre-receive hook. #{e.message}".strip
    rescue StandardError => e
      handle_merge_error(log_message: e.message)
      raise_error(GENERIC_ERROR_MESSAGE)
    end

    def after_merge
      log_info("Post merge started on JID #{merge_jid} with state #{state}")
      MergeRequests::PostMergeService.new(project: project, current_user: current_user).execute(merge_request)
      log_info("Post merge finished on JID #{merge_jid} with state #{state}")

      if delete_source_branch?
        MergeRequests::DeleteSourceBranchWorker.perform_async(@merge_request.id, @merge_request.source_branch_sha, branch_deletion_user.id)
      end
    end

    def clean_merge_jid
      merge_request.update_column(:merge_jid, nil)
    end

    def branch_deletion_user
      @merge_request.force_remove_source_branch? ? @merge_request.author : current_user
    end

    # Verify again that the source branch can be removed, since branch may be protected,
    # or the source branch may have been updated, or the user may not have permission
    #
    def delete_source_branch?
      params.fetch('should_remove_source_branch', @merge_request.force_remove_source_branch?) &&
        @merge_request.can_remove_source_branch?(branch_deletion_user)
    end

    def handle_merge_error(log_message:, save_message_on_model: false)
      Gitlab::AppLogger.error("MergeService ERROR: #{merge_request_info} - #{log_message}")
      @merge_request.update(merge_error: log_message) if save_message_on_model
    end

    def log_info(message)
      @logger ||= Gitlab::AppLogger
      @logger.info("#{merge_request_info} - #{message}")
    end

    def merge_request_info
      merge_request.to_reference(full: true)
    end

    def source_matches?
      # params-keys are symbols coming from the controller, but when they get
      # loaded from the database they're strings
      params.with_indifferent_access[:sha] == merge_request.diff_head_sha
    end

    def exclusive_lease(merge_request_id)
      strong_memoize(:"exclusive_lease_#{merge_request_id}") do
        lease_key = ['merge_requests_merge_service', merge_request_id].join(':')

        Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT)
      end
    end
  end
end
