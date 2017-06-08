module Gitlab
  class GitAccessWiki < GitAccess
    ERROR_MESSAGES = {
      geo:           "You can't push code to a secondary GitLab Geo node.",
      write_to_wiki: "You are not allowed to write to this project's wiki."
    }.freeze

    def guest_can_download_code?
      Guest.can?(:download_wiki_code, project)
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_wiki_code)
    end

    def check_single_change_access(change)
      unless user_access.can_do_action?(:create_wiki)
        raise UnauthorizedError, ERROR_MESSAGES[:write_to_wiki]
      end

      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        raise UnauthorizedError, ERROR_MESSAGES[:geo]
      end

      true
    end
  end
end
