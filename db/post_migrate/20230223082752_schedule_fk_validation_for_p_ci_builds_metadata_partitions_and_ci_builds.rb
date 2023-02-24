# frozen_string_literal: true

class ScheduleFkValidationForPCiBuildsMetadataPartitionsAndCiBuilds < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :p_ci_builds_metadata
  FK_NAME = :fk_e20479742e_p

  def up
    prepare_partitioned_async_foreign_key_validation TABLE_NAME, name: FK_NAME
  end

  def down
    unprepare_partitioned_async_foreign_key_validation TABLE_NAME, name: FK_NAME
  end
end
