module Commits
  class ChangeService < Commits::CreateService
    def initialize(*args)
      super

      @commit = params[:commit]
    end

    private

    def commit_change(action)
      raise NotImplementedError unless repository.respond_to?(action)

      repository.public_send(
        action,
        current_user,
        @commit,
        @branch_name,
        start_project: @start_project,
        start_branch_name: @start_branch)
    rescue Repository::CreateTreeError
      error_msg = "Sorry, we cannot #{action.to_s.dasherize} this #{@commit.change_type_title(current_user)} automatically.
                   This #{@commit.change_type_title(current_user)} may already have been #{action.to_s.dasherize}ed, or a more recent commit may have updated some of its content."
      raise ChangeError, error_msg
    end
  end
end
