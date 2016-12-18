module Gitlab
  class GitAccessWiki < GitAccess
    def guest_can_downlod_code?
      Guest.can?(:download_wiki_code, project)
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_wiki_code)
    end

    def change_access_check(change)
      if user_access.can_do_action?(:create_wiki)
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
