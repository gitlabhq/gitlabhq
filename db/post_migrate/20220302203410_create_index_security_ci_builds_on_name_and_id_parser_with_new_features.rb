# frozen_string_literal: true

class CreateIndexSecurityCiBuildsOnNameAndIdParserWithNewFeatures < Gitlab::Database::Migration[1.0]
  TABLE = "ci_builds"
  COLUMNS = %i[name id]
  INDEX_NAME = "index_security_ci_builds_on_name_and_id_parser_features"
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

  disable_ddl_transaction!

  def up
    add_concurrent_index(TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS)
  end

  def down
    remove_concurrent_index(TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS)
  end
end
