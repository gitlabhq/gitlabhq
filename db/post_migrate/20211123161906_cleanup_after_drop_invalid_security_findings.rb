# frozen_string_literal: true

class CleanupAfterDropInvalidSecurityFindings < Gitlab::Database::Migration[1.0]
  MIGRATION = "DropInvalidSecurityFindings"
  INDEX_NAME = "tmp_index_uuid_is_null"

  disable_ddl_transaction!

  def up
    # Make sure all jobs scheduled by
    # db/post_migrate/20211110151350_schedule_drop_invalid_security_findings.rb
    # are finished
    finalize_background_migration(MIGRATION)
    # Created by db/post_migrate/20211110151320_add_temporary_index_on_security_findings_uuid.rb
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :security_findings,
      :id,
      where: "uuid IS NULL",
      name: INDEX_NAME
    )
  end
end
