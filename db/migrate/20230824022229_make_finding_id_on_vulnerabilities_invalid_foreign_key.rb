# frozen_string_literal: true

class MakeFindingIdOnVulnerabilitiesInvalidForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :vulnerabilities, :vulnerability_occurrences,
      column: :finding_id, on_delete: :cascade, validate: false
  end

  def down
    remove_foreign_key_if_exists :vulnerabilities, column: :finding_id
  end
end
