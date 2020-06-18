# frozen_string_literal: true

class AddComposerMetadata < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :packages_composer_metadata, id: false do |t|
      t.references :package, primary_key: true, index: false, default: nil, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.binary :target_sha, null: false
    end
  end
end
