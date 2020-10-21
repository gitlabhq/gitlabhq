# frozen_string_literal: true

class AddPartialIndexToCiBuildsTableOnUserIdName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  INDEX_NAME = 'index_partial_ci_builds_on_user_id_name_parser_features'
  FILTER_CONDITION = <<~SQL
    (((type)::text = 'Ci::Build'::text) AND
      ((name)::text = ANY (
        ARRAY[
          ('container_scanning'::character varying)::text,
          ('dast'::character varying)::text,
          ('dependency_scanning'::character varying)::text,
          ('license_management'::character varying)::text,
          ('license_scanning'::character varying)::text,
          ('sast'::character varying)::text,
          ('coverage_fuzzing'::character varying)::text,
          ('secret_detection'::character varying)::text
        ]
      ))
    )
  SQL

  def up
    add_concurrent_index(:ci_builds,
                         [:user_id, :name],
                         where: FILTER_CONDITION,
                         name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
