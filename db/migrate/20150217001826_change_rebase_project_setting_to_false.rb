class ChangeRebaseProjectSettingToFalse < ActiveRecord::Migration
  def change
    change_column :projects, :merge_requests_rebase_default, :boolean, default: false
  end
end
