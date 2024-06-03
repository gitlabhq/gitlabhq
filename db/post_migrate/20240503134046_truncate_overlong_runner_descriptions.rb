# frozen_string_literal: true

class TruncateOverlongRunnerDescriptions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '17.1'

  def up
    each_batch(:ci_runners, of: 10_000) do |batch|
      execute(<<~SQL.squish)
        UPDATE ci_runners
        SET description = LEFT (description, 1024)
        WHERE LENGTH(description) > 1024
        AND id IN (#{batch.select(:id).to_sql})
      SQL
    end
  end

  def down
    # no-op - there's no way to retrieve truncated data
  end
end
