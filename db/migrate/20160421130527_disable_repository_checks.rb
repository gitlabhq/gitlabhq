class DisableRepositoryChecks < ActiveRecord::Migration
  def up
    change_column_default :application_settings, :repository_checks_enabled, false 
    execute 'UPDATE application_settings SET repository_checks_enabled = false'
  end

  def down
    change_column_default :application_settings, :repository_checks_enabled, true    
    execute 'UPDATE application_settings SET repository_checks_enabled = true'
  end
end
