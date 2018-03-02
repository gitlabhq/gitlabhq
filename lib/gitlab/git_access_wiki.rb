module Gitlab
  class GitAccessWiki < GitAccess
    ERROR_MESSAGES = {
      read_only:     "You can't push code to a read-only GitLab instance.",
      write_to_wiki: "You are not allowed to write to this project's wiki."
    }.freeze

    def guest_can_download_code?
      Guest.can?(:download_wiki_code, project)
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_wiki_code)
    end

    def check_single_change_access(change, _options = {})
      unless user_access.can_do_action?(:create_wiki)
        raise UnauthorizedError, ERROR_MESSAGES[:write_to_wiki]
      end

      if Gitlab::Database.read_only?
        raise UnauthorizedError, push_to_read_only_message
      end

      true
    end

    def push_to_read_only_message
      ERROR_MESSAGES[:read_only]
    end

    private

    def repository
      project.wiki.repository
    end
  end
end
