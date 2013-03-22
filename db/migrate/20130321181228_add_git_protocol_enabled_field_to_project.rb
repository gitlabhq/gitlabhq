class AddGitProtocolEnabledFieldToProject < ActiveRecord::Migration
  def change
    add_column :projects, :git_protocol_enabled, :boolean
  end
end
