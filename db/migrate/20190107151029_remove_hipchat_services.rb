# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveHipchatServices < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def up
    execute "DELETE FROM services WHERE type = 'HipchatService'"
  end

  def down
    # no-op
  end
end
