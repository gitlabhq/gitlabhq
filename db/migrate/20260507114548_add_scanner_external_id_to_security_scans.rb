# frozen_string_literal: true

class AddScannerExternalIdToSecurityScans < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/PreventAddingColumns -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/621
    add_column :security_scans, :scanner_external_id, :text, if_not_exists: true
    # rubocop:enable Migration/PreventAddingColumns

    add_text_limit :security_scans, :scanner_external_id, 255
  end

  def down
    remove_column :security_scans, :scanner_external_id, if_exists: true
  end
end
