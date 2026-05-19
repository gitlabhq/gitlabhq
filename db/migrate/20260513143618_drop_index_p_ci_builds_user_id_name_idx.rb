# frozen_string_literal: true

class DropIndexPCiBuildsUserIdNameIdx < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.0'

  INDEX_NAME = 'p_ci_builds_user_id_name_idx'

  def up
    remove_concurrent_partitioned_index_by_name :p_ci_builds, INDEX_NAME
  end

  def down
    # rubocop:disable Layout/LineLength -- where clause is very long
    add_concurrent_partitioned_index :p_ci_builds,
      [:user_id, :name],
      where: "(((type)::text = 'Ci::Build'::text) AND ((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('license_scanning'::character varying)::text, ('sast'::character varying)::text, ('coverage_fuzzing'::character varying)::text, ('secret_detection'::character varying)::text])))",
      name: INDEX_NAME
    # rubocop:enable Layout/LineLength
  end
end
