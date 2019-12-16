# frozen_string_literal: true

class CreatePackageBuildInfo < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :packages_build_infos do |t|
      t.references :package, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :integer, index: { unique: true }
      t.references :pipeline, index: true, null: true, foreign_key: { to_table: :ci_pipelines, on_delete: :nullify }, type: :integer
    end
  end
end
