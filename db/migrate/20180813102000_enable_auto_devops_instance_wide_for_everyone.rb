# frozen_string_literal: true

class EnableAutoDevopsInstanceWideForEveryone < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute "UPDATE application_settings SET auto_devops_enabled = true"
  end

  def down
    # No way to know here what their previous setting was...
  end
end
