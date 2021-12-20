# frozen_string_literal: true

# When the `ci_sources_pipelines` table was first introduced in GitLab
# 9.3 EE, the foreign key names generate for the table appeared to
# have been calculated via a hash using the table name
# `ci_pipeline_source_pipelines`. This led to a merge conflict and
# confusion during a CE to EE merge in GitLab 10.0, which regenerated
# the schema with the correct foreign key names.
#
# Hence anyone who installed GitLab prior to 10.0 may have been seeded
# the database with stale, incorrect foreign key names.
#
# During the Great BigInt Conversion of 2021, several migrations
# assumed that the foreign key `fk_be5624bf37` existed for
# `ci_sources_pipeline`. However, older installations may have had the
# correct foreign key under the name `fk_3f0c88d7dc`.
#
# To eliminate future confusion and migration failures, we now rename
# the foreign key constraints and index to what they should be today.
class FixCiSourcesPipelinesIndexNames < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'ci_sources_pipelines'

  # GitLab 9.5.4: https://gitlab.com/gitlab-org/gitlab/-/blob/v9.5.4-ee/db/schema.rb#L2026-2030
  # GitLab 10.0: https://gitlab.com/gitlab-org/gitlab/-/blob/v10.0.0-ee/db/schema.rb#L2064-2068
  OLD_TO_NEW_FOREIGN_KEY_DEFS = {
    'fk_3f0c88d7dc' => { table: :ci_builds, column: :source_job_id, name: 'fk_be5624bf37' },
    'fk_b8c0fac459' => { table: :ci_pipelines, column: :pipeline_id, name: 'fk_e1bad85861' },
    'fk_3a3e3cb83a' => { table: :ci_pipelines, column: :source_pipeline_id, name: 'fk_d4e29af7d7' },
    'fk_8868d0f3e4' => { table: :projects, column: :source_project_id, name: 'fk_acd9737679' },
    'fk_83b4346e48' => { table: :projects, name: 'fk_1e53c97c0a' }
  }
  OLD_INDEX_NAME = 'index_ci_pipeline_source_pipelines_on_source_job_id'
  NEW_INDEX_NAME = 'index_ci_sources_pipelines_on_source_job_id'

  def up
    OLD_TO_NEW_FOREIGN_KEY_DEFS.each do |old_name, entry|
      options = { column: entry[:column], name: old_name }.compact

      if foreign_key_exists?(TABLE_NAME, entry[:table], **options)
        rename_constraint(TABLE_NAME, old_name, entry[:name])
      end
    end

    if index_exists_by_name?(TABLE_NAME, OLD_INDEX_NAME)
      if index_exists_by_name?(TABLE_NAME, NEW_INDEX_NAME)
        remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
      else
        rename_index(TABLE_NAME, OLD_INDEX_NAME, NEW_INDEX_NAME)
      end
    end
  end

  # There's no reason to revert this change since it should apply on stale schemas
  def down; end
end
