# frozen_string_literal: true

class UpdateIndexSecureForApiFuzzingTelemetry < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  OLD_SECURE_INDEX_NAME = 'index_secure_ci_builds_on_user_id_created_at_parser_features'
  NEW_SECURE_INDEX_NAME = 'index_secure_ci_builds_on_user_id_name_created_at'

  def up
    add_concurrent_index(:ci_builds,
                         [:user_id, :name, :created_at],
                         where: "(((type)::text = 'Ci::Build'::text) AND ((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('license_scanning'::character varying)::text, ('sast'::character varying)::text, ('coverage_fuzzing'::character varying)::text, ('apifuzzer_fuzz'::character varying)::text, ('apifuzzer_fuzz_dnd'::character varying)::text, ('secret_detection'::character varying)::text])))",
                         name: NEW_SECURE_INDEX_NAME)
    remove_concurrent_index_by_name :ci_builds, OLD_SECURE_INDEX_NAME
  end

  def down
    add_concurrent_index(:ci_builds,
                         [:user_id, :created_at],
                         where: "(((type)::text = 'Ci::Build'::text) AND ((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('license_scanning'::character varying)::text, ('sast'::character varying)::text, ('secret_detection'::character varying)::text])))",
                         name: OLD_SECURE_INDEX_NAME)
    remove_concurrent_index_by_name :ci_builds, NEW_SECURE_INDEX_NAME
  end
end
