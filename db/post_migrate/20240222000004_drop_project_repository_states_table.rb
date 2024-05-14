# frozen_string_literal: true

class DropProjectRepositoryStatesTable < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  def up
    drop_table :project_repository_states, if_exists: true
  end

  def down
    return if table_exists?(:project_repository_states)

    create_table :project_repository_states, id: :integer do |t|
      t.integer :project_id, null: false
      t.binary :repository_verification_checksum, using: 'repository_verification_checksum::bytea'
      t.binary :wiki_verification_checksum, using: 'wiki_verification_checksum::bytea'
      t.string :last_repository_verification_failure
      t.string :last_wiki_verification_failure
      t.datetime_with_timezone :repository_retry_at
      t.datetime_with_timezone :wiki_retry_at
      t.integer :repository_retry_count
      t.integer :wiki_retry_count
      t.datetime_with_timezone :last_repository_verification_ran_at
      t.datetime_with_timezone :last_wiki_verification_ran_at
      t.datetime_with_timezone :last_repository_updated_at
      t.datetime_with_timezone :last_wiki_updated_at

      t.index [:project_id, :last_repository_verification_ran_at],
        name: :idx_repository_states_on_last_repository_verification_ran_at,
        where: "(repository_verification_checksum IS NOT NULL) AND (last_repository_verification_failure IS NULL)"

      t.index [:project_id, :last_wiki_verification_ran_at],
        name: :idx_repository_states_on_last_wiki_verification_ran_at,
        where: "(wiki_verification_checksum IS NOT NULL) AND (last_wiki_verification_failure IS NULL)"

      t.index :last_repository_verification_failure,
        name: :idx_repository_states_on_repository_failure_partial,
        where: "last_repository_verification_failure IS NOT NULL"

      t.index :last_wiki_verification_failure,
        name: :idx_repository_states_on_wiki_failure_partial,
        where: "last_wiki_verification_failure IS NOT NULL"

      # rubocop:disable Layout/LineLength -- Where clause is just too long.
      t.index :project_id,
        name: :idx_repository_states_outdated_checksums,
        where: "((repository_verification_checksum IS NULL) AND (last_repository_verification_failure IS NULL)) OR ((wiki_verification_checksum IS NULL) AND (last_wiki_verification_failure IS NULL))"
      # rubocop:enable Layout/LineLength

      t.index :project_id,
        name: :index_project_repository_states_on_project_id,
        unique: true
    end
  end
end
