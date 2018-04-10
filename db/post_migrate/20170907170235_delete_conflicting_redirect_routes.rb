# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DeleteConflictingRedirectRoutes < ActiveRecord::Migration
  def up
    # No-op.
    # See https://gitlab.com/gitlab-com/infrastructure/issues/3460#note_53223252
  end

  def down
    # nothing
  end
end
