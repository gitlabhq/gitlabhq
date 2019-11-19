# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# Code of this migration was removed after execution on gitlab.com
# https://gitlab.com/gitlab-org/gitlab/issues/34018
# Empty migration is left here to avoid any problems with rolling back
class ScheduleFixGitlabComPagesAccessLevel < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
  end

  def down
  end
end
