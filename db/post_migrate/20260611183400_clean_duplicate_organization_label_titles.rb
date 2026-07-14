# frozen_string_literal: true

class CleanDuplicateOrganizationLabelTitles < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.2'

  def up
    labels = define_batchable_model(:labels)

    labels.where.not(organization_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      sleep 0.1

      connection.execute(
        <<~SQL
          WITH relation AS MATERIALIZED (
            #{batch.select(:id).to_sql}
          )
          UPDATE labels AS l
          SET title = l.title || ' [dup ' || l.id || ']'
          FROM relation r
          WHERE l.id = r.id
            AND EXISTS (
              SELECT 1 FROM labels o
              WHERE o.id <> l.id
                AND o.organization_id = l.organization_id
                AND o.title = l.title
            );
        SQL
      )
    end
  end

  def down
    # no-op
    # we don't want to revert a data cleanup
  end
end
