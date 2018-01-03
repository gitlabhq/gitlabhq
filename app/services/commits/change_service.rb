module Commits
  class ChangeService < Commits::CreateService
    def initialize(*args)
      super

      @commit = params[:commit]
    end

    private

    def commit_change(action)
      raise NotImplementedError unless repository.respond_to?(action)

      # rubocop:disable GitlabSecurity/PublicSend
      message = @commit.public_send(:"#{action}_message", current_user)

      # rubocop:disable GitlabSecurity/PublicSend
      repository.public_send(
        action,
        current_user,
        @commit,
        @branch_name,
        message,
        start_project: @start_project,
        start_branch_name: @start_branch)
    rescue Gitlab::Git::Repository::CreateTreeError
      error_msg = "Sorry, we cannot #{action.to_s.dasherize} this #{@commit.change_type_title(current_user)} automatically.
                   This #{@commit.change_type_title(current_user)} may already have been #{action.to_s.dasherize}ed, or a more recent commit may have updated some of its content."
      raise ChangeError, error_msg
    end
  end
end
