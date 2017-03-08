module Gitlab
  class GitAccessWiki < GitAccess
    def guest_can_download_code?
      Guest.can?(:download_wiki_code, project)
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_wiki_code)
    end

    def check_single_change_access(change)
      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        build_status_object(false, "You can't push code to a secondary GitLab Geo node.")
      elsif user_access.can_do_action?(:create_wiki)
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
