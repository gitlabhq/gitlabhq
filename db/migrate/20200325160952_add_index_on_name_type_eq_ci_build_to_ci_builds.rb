# frozen_string_literal: true

class AddIndexOnNameTypeEqCiBuildToCiBuilds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_on_name_and_security_type_eq_ci_build'

  def up
    add_concurrent_index :ci_builds, [:name, :id],
                         name: INDEX_NAME,
                         where: "((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('sast'::character varying)::text, ('license_scanning'::character varying)::text])) AND ((type)::text = 'Ci::Build'::text)"
  end

  def down
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
