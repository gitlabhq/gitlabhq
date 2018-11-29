class AddConfigSourceToPipelines < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column(:ci_pipelines, :config_source, :integer, allow_null: true)
  end
end
