# == GitHost role
#
# Provide a shortcut to Gitlab::Gitolite instance
#
# Used by Project, UsersProject
#
module GitHost
  def git_host
    Gitlab::Gitolite.new
  end
end
