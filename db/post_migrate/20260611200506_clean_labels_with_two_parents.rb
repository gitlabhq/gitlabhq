# frozen_string_literal: true

class CleanLabelsWithTwoParents < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.2'

  def up
    labels = define_batchable_model(:labels)

    labels.where('group_id IS NOT NULL AND project_id IS NOT NULL').each_batch(of: BATCH_SIZE) do |batch|
      sleep 0.1

      connection.execute(
        <<~SQL
          WITH relation AS MATERIALIZED (
            #{batch.select(:id).limit(BATCH_SIZE).to_sql}
          )
          UPDATE labels AS l
          SET
            project_id = CASE WHEN l.type = 'ProjectLabel' THEN l.project_id ELSE NULL END,
            group_id   = CASE WHEN l.type = 'GroupLabel'   THEN l.group_id   ELSE NULL END,
            title = CASE
              WHEN l.type = 'ProjectLabel' THEN
                CASE
                  WHEN EXISTS (
                    SELECT 1 FROM labels o
                    WHERE o.id <> l.id
                      AND o.project_id = l.project_id
                      AND o.title = l.title
                  )
                  THEN l.title || ' [dup ' || l.id || ']'
                  ELSE l.title
                END
              ELSE
                CASE
                  WHEN EXISTS (
                    SELECT 1 FROM labels o
                    WHERE o.id <> l.id
                      AND o.group_id = l.group_id
                      AND o.title = l.title
                  )
                  THEN l.title || ' [dup ' || l.id || ']'
                  ELSE l.title
                END
            END
          FROM relation r
          WHERE l.id = r.id;
        SQL
      )
    end
  end

  def down
    # no-op
    # we don't want to revert a data cleanup
  end
end
