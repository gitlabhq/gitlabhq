# frozen_string_literal: true

class UpdateSecureSmauIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_secure_ci_builds_on_user_id_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :ci_builds,
      [:user_id, :created_at],
      where: "(((type)::text = 'Ci::Build'::text) AND ((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('license_scanning'::character varying)::text, ('sast'::character varying)::text, ('secret_detection'::character varying)::text])))",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
