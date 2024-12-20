# frozen_string_literal: true

class CreateInstanceIntegrationsTable < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    create_table :instance_integrations, id: :bigserial do |t|
      t.timestamps_with_timezone null: false
      t.integer :comment_detail
      t.boolean :active, default: false, null: false
      t.boolean :push_events, default: true
      t.boolean :issues_events, default: true
      t.boolean :merge_requests_events, default: true
      t.boolean :tag_push_events, default: true
      t.boolean :note_events, default: true, null: false
      t.boolean :wiki_page_events, default: true
      t.boolean :pipeline_events, default: false, null: false
      t.boolean :confidential_issues_events, default: true, null: false
      t.boolean :commit_events, default: true, null: false
      t.boolean :job_events, default: false, null: false
      t.boolean :confidential_note_events, default: true
      t.boolean :deployment_events, default: false, null: false
      t.boolean :comment_on_event_enabled, default: true, null: false
      t.boolean :alert_events
      t.boolean :vulnerability_events, default: false, null: false
      t.boolean :archive_trace_events, default: false, null: false
      t.boolean :incident_events, default: false, null: false
      t.boolean :group_mention_events, default: false, null: false
      t.boolean :group_confidential_mention_events, default: false, null: false
      t.text :category, default: 'common', limit: 255
      t.text :type, limit: 255
      t.binary :encrypted_properties
      t.binary :encrypted_properties_iv
    end
  end

  def down
    drop_table :instance_integrations, if_exists: true
  end
end
