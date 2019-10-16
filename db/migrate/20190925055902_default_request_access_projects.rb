# frozen_string_literal: true

class DefaultRequestAccessProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :projects, :request_access_enabled, true
  end

  def down
    change_column_default :projects, :request_access_enabled, false
  end
end
