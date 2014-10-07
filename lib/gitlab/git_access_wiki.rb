module Gitlab
  class GitAccessWiki < GitAccess
    def change_allowed?(user, project, change)
      user.can?(:write_wiki, project)
    end
  end
end
