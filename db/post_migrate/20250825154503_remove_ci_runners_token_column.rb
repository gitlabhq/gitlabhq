# frozen_string_literal: true

class RemoveCiRunnersTokenColumn < Gitlab::Database::Migration[2.3]
  INDEX_COLUMN_NAMES = %i[token runner_type].freeze

  disable_ddl_transaction!

  milestone '18.4'

  def up
    remove_column :ci_runners, :token, if_exists: true
  end

  def down
    add_column :ci_runners, :token, :text, if_not_exists: true

    %i[ci_runners instance_type_ci_runners group_type_ci_runners project_type_ci_runners].each do |table_name|
      add_check_constraint(table_name, 'char_length(token) <= 128', 'check_af25130d5a', validate: false)
    end

    opts = { unique: true, where: 'token IS NOT NULL' }

    {
      instance_type_ci_runners: 'idx_instance_type_ci_runners_on_token_runner_type_when_not_null',
      group_type_ci_runners: 'idx_group_type_ci_runners_on_token_runner_type_when_not_null',
      project_type_ci_runners: 'idx_project_type_ci_runners_on_token_runner_type_when_not_null'
    }.each do |table_name, index_name|
      add_concurrent_index(table_name, INDEX_COLUMN_NAMES, name: index_name, allow_partition: true, **opts)
    end

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- existing logic from add_concurrent_partitioned_index
    with_lock_retries do
      add_index( # rubocop:disable Migration/AddIndex -- no need for add_concurrent_index as this is just the routing table
        :ci_runners,
        INDEX_COLUMN_NAMES,
        name: 'index_ci_runners_on_token_and_runner_type_when_token_not_null',
        **opts
      )
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end
end
