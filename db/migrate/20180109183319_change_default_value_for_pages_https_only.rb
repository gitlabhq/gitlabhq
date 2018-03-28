class ChangeDefaultValueForPagesHttpsOnly < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :projects, :pages_https_only, true
  end

  def down
    change_column_default :projects, :pages_https_only, nil
  end
end
