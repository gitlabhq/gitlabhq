class AddMaxArtifactsSizeToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :max_artifacts_size, :integer, default: 100, null: false
  end
end
