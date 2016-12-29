module Gitlab
  class GitAccessWiki < GitAccess
    def guest_can_download_code?
      Guest.can?(:download_wiki_code, project)
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_wiki_code)
    end

<<<<<<< HEAD
    def change_access_check(change)
      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        build_status_object(false, "You can't push code to a secondary GitLab Geo node.")
      elsif user_access.can_do_action?(:create_wiki)
=======
    def check_single_change_access(change)
      if user_access.can_do_action?(:create_wiki)
>>>>>>> 714f70a38df10e678bffde6e6081a97e31d8317c
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
