# frozen_string_literal: true

class ReplacePCiBuildsMetadataForeignKeyV4 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!

  def up
    return unless should_run?
    return if foreign_key_exists?(:p_ci_builds_metadata, :p_ci_builds, name: :temp_fk_e20479742e_p)

    with_lock_retries do
      execute(<<~SQL.squish)
        LOCK TABLE ci_builds, p_ci_builds, p_ci_builds_metadata IN ACCESS EXCLUSIVE MODE;

        ALTER TABLE p_ci_builds_metadata
          ADD CONSTRAINT temp_fk_e20479742e_p
          FOREIGN KEY (partition_id, build_id)
          REFERENCES p_ci_builds (partition_id, id)
          ON  UPDATE CASCADE ON DELETE CASCADE;
      SQL
    end
  end

  def down
    return unless should_run?

    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_builds_metadata, :p_ci_builds,
        name: :temp_fk_e20479742e_p,
        reverse_lock_order: true
    end
  end

  private

  def should_run?
    can_execute_on?(:ci_builds_metadata, :ci_builds)
  end
end
