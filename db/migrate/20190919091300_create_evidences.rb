# frozen_string_literal: true

class CreateEvidences < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :evidences do |t|
      t.references :release, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone
      t.binary :summary_sha
      t.jsonb :summary, null: false, default: {}
    end
  end
end
