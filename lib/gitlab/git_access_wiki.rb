module Gitlab
  class GitAccessWiki < GitAccess
    def change_access_check(change)
<<<<<<< HEAD
      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        build_status_object(false, "You can't push code to a secondary GitLab Geo node.")
      elsif user_access.can_do_action?(:create_wiki)
=======
      if user_access.can_do_action?(:create_wiki)
>>>>>>> a27212ab908d5161f5a75b27c4616c11f497f5d4
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
