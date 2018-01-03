class AddConfigSourceToPipelines < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column(:ci_pipelines, :config_source, :integer, allow_null: true)
  end
end
