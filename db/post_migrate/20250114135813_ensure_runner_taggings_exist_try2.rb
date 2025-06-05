# frozen_string_literal: true

class EnsureRunnerTaggingsExistTry2 < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 500

  class CiRunnerMigration < MigrationRecord
    include ::EachBatch

    self.primary_key = :id
  end

  def up
    return unless needs_migration?

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

  # We don't know for sure whether the migration from taggings to
  # ci_runner_taggings ran successfully. Here we take a guess and assume
  # that if the ci_runner_taggings table doesn't have 50% of the entries
  # from the taggings table then we need to copy the data over. This
  # might have an unintended side effect of adding taggings that were
  # removed, but that is generally better than the alternative of
  # missing taggings altogether.
  def needs_migration?
    return true if ENV.key?('FORCE_COPY_RUNNER_TAGGINGS')

    old_count = disable_statement_timeout do
      connection.select_value(%(SELECT COUNT(*) FROM taggings WHERE taggable_type = 'Ci::Runner'))
    end

    new_count = disable_statement_timeout do
      connection.select_value(%(SELECT COUNT(*) FROM ci_runner_taggings))
    end

    new_count < 0.5 * old_count
  end
end
