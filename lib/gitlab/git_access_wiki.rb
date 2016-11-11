module Gitlab
  class GitAccessWiki < GitAccess
    def check_single_change_access(change)
      if user_access.can_do_action?(:create_wiki)
        build_status_object(true)
      else
        build_status_object(false, "You are not allowed to write to this project's wiki.")
      end
    end
  end
end
