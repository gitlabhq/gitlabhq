# frozen_string_literal: true

class ChangeDefaultOfAutoDevopsInstanceWide < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :auto_devops_enabled, true
  end

  def down
    change_column_default :application_settings, :auto_devops_enabled, false
  end
end
