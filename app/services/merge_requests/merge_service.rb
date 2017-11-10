module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class MergeService < MergeRequests::BaseService
    MergeError = Class.new(StandardError)

    attr_reader :merge_request, :source

    def execute(merge_request)
      if project.merge_requests_ff_only_enabled && !self.is_a?(FfMergeService)
        FfMergeService.new(project, current_user, params).execute(merge_request)
        return
      end

      @merge_request = merge_request

      error_check!

      merge_request.in_locked_state do
        if commit
          after_merge
          clean_merge_jid
          success
        end
      end
    rescue MergeError => e
      handle_merge_error(log_message: e.message, save_message_on_model: true)
    end

    private

    def error_check!
      error =
        if @merge_request.should_be_rebased?
          'Only fast-forward merge is allowed for your project. Please update your source branch'
        elsif !@merge_request.mergeable?
          'Merge request is not mergeable'
        elsif !source
          'No source for merge'
        end

      raise MergeError, error if error
    end

    def commit
      message = params[:commit_message] || merge_request.merge_commit_message

      commit_id = repository.merge(current_user, source, merge_request, message)

      raise MergeError, 'Conflicts detected during merge' unless commit_id

      merge_request.update(merge_commit_sha: commit_id)
    rescue Gitlab::Git::HooksService::PreReceiveError => e
      raise MergeError, e.message
    rescue StandardError => e
      raise MergeError, "Something went wrong during merge: #{e.message}"
    ensure
      merge_request.update(in_progress_merge_commit_sha: nil)
    end

    def after_merge
      MergeRequests::PostMergeService.new(project, current_user).execute(merge_request)

      if params[:should_remove_source_branch].present? || @merge_request.force_remove_source_branch?
        # Verify again that the source branch can be removed, since branch may be protected,
        # or the source branch may have been updated.
        if @merge_request.can_remove_source_branch?(branch_deletion_user)
          DeleteBranchService.new(@merge_request.source_project, branch_deletion_user)
            .execute(merge_request.source_branch)
        end
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
      Rails.logger.error("MergeService ERROR: #{merge_request_info} - #{log_message}")
      @merge_request.update(merge_error: log_message) if save_message_on_model
    end

    def merge_request_info
      merge_request.to_reference(full: true)
    end

    def source
      @source ||= @merge_request.diff_head_sha
    end
  end
end
