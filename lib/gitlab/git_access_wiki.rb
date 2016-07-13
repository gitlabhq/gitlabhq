module Gitlab
  class GitAccessWiki < GitAccess
    def change_access_check(change)
      if user.can?(:create_wiki, project)
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
