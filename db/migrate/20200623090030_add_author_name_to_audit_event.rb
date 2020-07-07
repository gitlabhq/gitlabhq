# frozen_string_literal: true

class AddAuthorNameToAuditEvent < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    unless column_exists?(:audit_events, :author_name)
      with_lock_retries do
        add_column :audit_events, :author_name, :text
      end
    end

    add_text_limit :audit_events, :author_name, 255
  end

  def down
    remove_column :audit_events, :author_name
  end
end
