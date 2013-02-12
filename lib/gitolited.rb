# == Gitolited mixin
#
# Provide a shortcut to Gitlab::Shell instance by gitlab_shell
#
# Used by Project, UsersProject, etc
#
module Gitolited
  def gitlab_shell
    Gitlab::Shell.new
  end
end
