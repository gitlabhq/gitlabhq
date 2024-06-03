# frozen_string_literal: true

class TruncateOverlongRunnerNames < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '17.1'

  def up
    each_batch(:ci_runners, of: 10_000) do |batch|
      execute(<<~SQL.squish)
        UPDATE ci_runners
        SET name = LEFT (name, 256)
        WHERE LENGTH(name) > 256
        AND id IN (#{batch.select(:id).to_sql})
      SQL
    end
  end

  def down
    # no-op - there's no way to retrieve truncated data
  end
end
