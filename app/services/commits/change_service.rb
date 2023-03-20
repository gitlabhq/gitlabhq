# frozen_string_literal: true

module Commits
  class ChangeService < Commits::CreateService
    def initialize(*args)
      super

      @commit = params[:commit]
      @message = params[:message]
    end

    private

    def commit_change(action)
      raise NotImplementedError unless repository.respond_to?(action)

      # rubocop:disable GitlabSecurity/PublicSend
      message =
        @message || @commit.public_send(:"#{action}_message", current_user)

      repository.public_send(
        action,
        current_user,
        @commit,
        @branch_name,
        message,
        start_project: @start_project,
        start_branch_name: @start_branch,
        dry_run: @dry_run
      )
    rescue Gitlab::Git::Repository::CreateTreeError => ex
      type = @commit.change_type_title(current_user)

      status = case [type, action]
               when ['commit', :cherry_pick]
                 s_("MergeRequests|Commit cherry-pick failed")
               when ['commit', :revert]
                 s_("MergeRequests|Commit revert failed")
               when ['merge request', :cherry_pick]
                 s_("MergeRequests|Merge request cherry-pick failed")
               when ['merge request', :revert]
                 s_("MergeRequests|Merge request revert failed")
               end

      detail = s_("MergeRequests|Can't perform this action automatically. " \
        "It may have already been done, or a more recent commit may have updated some of this content. " \
        "Please perform this action locally.")

      error_msg = "#{status}: #{detail}"

      raise ChangeError.new(error_msg, ex.error_code)
    end
  end
end
