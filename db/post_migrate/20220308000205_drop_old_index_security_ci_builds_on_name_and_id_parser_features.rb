# frozen_string_literal: true

class DropOldIndexSecurityCiBuildsOnNameAndIdParserFeatures < Gitlab::Database::Migration[1.0]
  TABLE = "ci_builds"
  COLUMNS = %i[name id]
  INDEX_NAME = "index_security_ci_builds_on_name_and_id_parser_features_old"
  CONSTRAINTS = "(name::text = ANY (ARRAY['container_scanning'::character varying::text,
                                         'dast'::character varying::text,
                                         'dependency_scanning'::character varying::text,
                                         'license_management'::character varying::text,
                                         'sast'::character varying::text,
                                         'secret_detection'::character varying::text,
                                         'coverage_fuzzing'::character varying::text,
                                         'license_scanning'::character varying::text])
                ) AND type::text = 'Ci::Build'::text"

  disable_ddl_transaction!

  def up
    remove_concurrent_index(TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS)
  end

  def down
    add_concurrent_index(TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS)
  end
end
