# frozen_string_literal: true

class AddOverriddenUuidToSecurityFindings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :security_findings, :overridden_uuid, :uuid, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column :security_findings, :overridden_uuid
    end
  end
end
