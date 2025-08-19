# frozen_string_literal: true

class BackfillLabelsWithGroupProjectMissing < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 150

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.3'

  def up
    each_batch(
      :labels,
      of: BATCH_SIZE,
      scope: ->(labels) { labels.where('group_id IS NULL AND project_id IS NULL') }
    ) do |batch|
      connection.execute(
        <<~SQL
          UPDATE
            "labels"
          SET
            "organization_id" = 1
          WHERE
            "labels"."id" IN (#{batch.select(:id).limit(BATCH_SIZE).to_sql})
        SQL
      )
    end
  end

  def down
    # no-op
  end
end
