module Gitlab
  class GitAccessWiki < GitAccess
    def change_access_check(user, project, change)
      if user.can?(:write_wiki, project)
        build_status_object(true)
      else
        build_status_object(false, "You don't have access")
      end
    end
  end
end
