module Gitlab
  class GitAccessWiki < GitAccess
    def change_access_check(change)
      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        build_status_object(false, "You can't push code to a secondary GitLab Geo node.")
      elsif user.can?(:create_wiki, project)
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
