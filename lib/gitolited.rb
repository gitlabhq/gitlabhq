# == Gitolited mixin
#
# Provide a shortcut to Gitlab::Gitolite instance by gitolite
#
# Used by Project, UsersProject, etc
#
module Gitolited
  def gitolite
    Gitlab::Shell.new
  end
end
