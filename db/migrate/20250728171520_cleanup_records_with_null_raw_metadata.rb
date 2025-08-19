# frozen_string_literal: true

class CleanupRecordsWithNullRawMetadata < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  milestone '18.3'

  class Finding < ::SecApplicationRecord
    include EachBatch

    self.table_name = "vulnerability_occurrences"
  end

  def up
    # no-op - this is required to allow rollback of RemoveNotNullConstraintFromRawMetadata
  end

  def down
    Finding.each_batch do |relation|
      relation.where(raw_metadata: nil).delete_all
    end
  end
end
