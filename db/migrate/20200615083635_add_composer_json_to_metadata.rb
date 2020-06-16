# frozen_string_literal: true

class AddComposerJsonToMetadata < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :packages_composer_metadata, :composer_json, :jsonb, default: {}, null: false
  end
end
