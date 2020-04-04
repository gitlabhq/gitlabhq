# frozen_string_literal: true

class RemoveIndexCiBuildsOnNameForSecurityReportsValues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_on_name_for_security_reports_values'

  def up
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_builds,
                         :name,
                         name: INDEX_NAME,
                         where: "((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('sast'::character varying)::text, ('license_scanning'::character varying)::text]))"
  end
end
