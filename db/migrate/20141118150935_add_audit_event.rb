class AddAuditEvent < ActiveRecord::Migration
  def change
    create_table :audit_events do |t|
      t.integer :author_id, null: false
      t.string  :type, null: false

      # "Namespace" where the change occurs
      # eg. On a project, group or user
      t.integer :entity_id, null: false
      t.string  :entity_type, null: false

      # Details for the event
      t.text  :details

      t.timestamps
    end

    add_index :audit_events, :author_id
    add_index :audit_events, :type
    add_index :audit_events, [:entity_id, :entity_type]
  end
end
