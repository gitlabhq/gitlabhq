# frozen_string_literal: true

class CreateProjectCiFeatureUsages < ActiveRecord::Migration[6.1]
  def change
    create_table :project_ci_feature_usages do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.integer :feature, null: false, limit: 2
      t.boolean :default_branch, default: false, null: false
      t.index [:project_id, :feature, :default_branch], unique: true, name: 'index_project_ci_feature_usages_unique_columns'
    end
  end
end
