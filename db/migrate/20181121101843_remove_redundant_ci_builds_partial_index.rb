# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveRedundantCiBuildsPartialIndex < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index(*index_arguments)
  end

  def down
    add_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :ci_builds,
      [:project_id, :status],
      {
        name: 'index_ci_builds_project_id_and_status_for_live_jobs_partial',
        where: "((status)::text = ANY (ARRAY[('running'::character varying)::text, ('pending'::character varying)::text, ('created'::character varying)::text]))"
      }
    ]
  end
end
