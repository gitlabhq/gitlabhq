class MigrateToNewShell < ActiveRecord::Migration
  def change
    gitlab_shell_path = Gitlab.config.gitlab_shell.path
    if system("sh #{gitlab_shell_path}/support/rewrite-hooks.sh")
      puts 'Repositories updated with new hooks'
    else
      raise 'Failed to rewrite gitlab-shell hooks in repositories'
    end
  end
end
