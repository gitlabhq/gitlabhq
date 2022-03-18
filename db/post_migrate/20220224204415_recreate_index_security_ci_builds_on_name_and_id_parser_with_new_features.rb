# frozen_string_literal: true

class RecreateIndexSecurityCiBuildsOnNameAndIdParserWithNewFeatures < Gitlab::Database::Migration[1.0]
  TABLE = "ci_builds"
  OLD_INDEX_NAME = "index_security_ci_builds_on_name_and_id_parser_features"
  NEW_INDEX_NAME = "index_security_ci_builds_on_name_and_id_parser_features_old"
  COLUMNS = %i[name id]
  CONSTRAINTS = "(name::text = ANY (ARRAY['container_scanning'::character varying::text,
                                         'dast'::character varying::text,
                                         'dependency_scanning'::character varying::text,
                                         'license_management'::character varying::text,
                                         'sast'::character varying::text,
                                         'secret_detection'::character varying::text,
                                         'coverage_fuzzing'::character varying::text,
                                         'license_scanning'::character varying::text,
                                         'apifuzzer_fuzz'::character varying::text,
                                         'apifuzzer_fuzz_dnd'::character varying::text])
                ) AND type::text = 'Ci::Build'::text"

  enable_lock_retries!

  def up
    rename_index(TABLE, OLD_INDEX_NAME, NEW_INDEX_NAME)
    prepare_async_index TABLE, COLUMNS, name: OLD_INDEX_NAME, where: CONSTRAINTS
  end

  def down
    unprepare_async_index TABLE, COLUMNS, name: OLD_INDEX_NAME
    rename_index(TABLE, NEW_INDEX_NAME, OLD_INDEX_NAME)
  end
end
