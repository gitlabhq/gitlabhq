# frozen_string_literal: true

class PmCheckpointsRemoveAdvisoryEntries < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_pm

  def up
    execute("DELETE FROM pm_checkpoints
      WHERE data_type = #{Enums::PackageMetadata::DATA_TYPES[:licenses]} and version_format = 1")
    execute("UPDATE pm_checkpoints SET data_type = #{Enums::PackageMetadata::DATA_TYPES[:licenses]}
      WHERE data_type = #{Enums::PackageMetadata::DATA_TYPES[:advisories]} and version_format = 1")
  end

  def down
    # noop
  end
end
