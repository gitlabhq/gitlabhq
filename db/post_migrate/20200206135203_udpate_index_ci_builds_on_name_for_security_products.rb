# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UdpateIndexCiBuildsOnNameForSecurityProducts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_builds_on_name_for_security_products_values'
  INDEX_NAME_NEW = 'index_ci_builds_on_name_for_security_reports_values'
  INITIAL_INDEX = "((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('sast'::character varying)::text"

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_builds,
                         :name,
                         name: INDEX_NAME_NEW,
                         where: INITIAL_INDEX + ", ('license_scanning'::character varying)::text]))")

    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME)
  end

  def down
    add_concurrent_index(:ci_builds,
                         :name,
                         name: INDEX_NAME,
                         where: INITIAL_INDEX + ']))')

    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME_NEW)
  end
end
