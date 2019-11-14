# frozen_string_literal: true

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
      repository.public_send(
        action,
        current_user,
        @commit,
        @branch_name,
        message,
        start_project: @start_project,
        start_branch_name: @start_branch)
    rescue Gitlab::Git::Repository::CreateTreeError => ex
      act = action.to_s.dasherize
      type = @commit.change_type_title(current_user)

      error_msg = "Sorry, we cannot #{act} this #{type} automatically. " \
        "This #{type} may already have been #{act}ed, or a more recent " \
        "commit may have updated some of its content."

      raise ChangeError.new(error_msg, ex.error_code)
    end
  end
end
