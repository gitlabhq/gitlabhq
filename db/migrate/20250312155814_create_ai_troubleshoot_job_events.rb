# frozen_string_literal: true

class CreateAiTroubleshootJobEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    # rubocop:disable Migration/Datetime -- "timestamp" is a column name
    create_table :ai_troubleshoot_job_events,
      options: 'PARTITION BY RANGE (timestamp)',
      primary_key: [:id, :timestamp] do |t|
      t.bigserial :id, null: false
      t.datetime_with_timezone :timestamp, null: false
      t.belongs_to :user, null: false
      t.references :job, null: false
      t.references :project, foreign_key: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :event, null: false, limit: 2
      t.text :namespace_path, limit: 255
      t.jsonb :payload
    end
    # rubocop:enable Migration/Datetime
  end

  def down
    drop_table :ai_troubleshoot_job_events
  end
end
