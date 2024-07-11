# frozen_string_literal: true

class CreateTablePCiBuildTags < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  enable_lock_retries!

  OPTIONS = {
    if_not_exists: true,
    options: 'PARTITION BY LIST (partition_id)',
    primary_key: [:id, :partition_id]
  }

  def up
    create_table(:p_ci_build_tags, **OPTIONS) do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigserial :id, null: false
      t.bigint :tag_id, null: false
      t.bigint :build_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false

      t.index [:tag_id, :build_id, :partition_id], unique: true
      t.index [:build_id, :partition_id]
      t.index [:project_id]
    end
  end

  def down
    drop_table :p_ci_build_tags
  end
end
