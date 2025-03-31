# frozen_string_literal: true

class EnsureRunnerTaggingsExist < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 500

  class CiRunnerMigration < MigrationRecord
    include ::EachBatch

    self.primary_key = :id
  end

  def up
    return unless new_taggings_table_is_empty?

    CiRunnerMigration.table_name = find_new_runners_table_name

    CiRunnerMigration.each_batch(of: BATCH_SIZE) do |batch|
      scope = batch
        .joins("inner join taggings on #{CiRunnerMigration.quoted_table_name}.id = taggings.taggable_id")
        .where(taggings: { taggable_type: 'Ci::Runner' })
        .select(:tag_id, 'taggable_id as runner_id', :sharding_key_id, :runner_type)

      connection.execute(<<~SQL.squish)
        INSERT INTO ci_runner_taggings(tag_id, runner_id, sharding_key_id, runner_type)
        (#{scope.to_sql})
        ON CONFLICT DO NOTHING;
      SQL
    end
  end

  def down; end

  private

  # Even though we introduce this at a specific timestamp,
  # it could still be executed from a patch release in which the table
  # was already renamed.
  def find_new_runners_table_name
    if connection.table_exists?(:ci_runners_e59bb2812d)
      :ci_runners_e59bb2812d
    else
      :ci_runners
    end
  end

  def new_taggings_table_is_empty?
    !connection.select_value('SELECT true FROM ci_runner_taggings LIMIT 1')
  end
end
