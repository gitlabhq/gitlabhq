# frozen_string_literal: true

class CreateCiPipelinesConfig < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :ci_pipelines_config, id: false do |t|
      t.references :pipeline,
                   primary_key: true,
                   foreign_key: { to_table: :ci_pipelines, on_delete: :cascade }
      t.text :content, null: false
    end
  end
end
