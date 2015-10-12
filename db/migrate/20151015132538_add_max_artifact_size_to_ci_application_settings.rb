class AddMaxArtifactSizeToCiApplicationSettings < ActiveRecord::Migration
  def change
    add_column :ci_application_settings, :max_artifact_size, :integer, default: 100, null: false
  end
end
