# frozen_string_literal: true

class RemoveCustomerRelationContactsForEpicType < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 1000
  EPIC_WORK_ITEM_TYPE_ID = 8

  def up
    each_batch(:issue_customer_relations_contacts, of: BATCH_SIZE) do |batch|
      connection.execute(
        <<~SQL
          DELETE FROM issue_customer_relations_contacts
          WHERE id IN (
            SELECT icrc.id
            FROM issue_customer_relations_contacts icrc
            JOIN issues i ON icrc.issue_id = i.id
            WHERE i.work_item_type_id = #{EPIC_WORK_ITEM_TYPE_ID}
              AND icrc.id IN (#{batch.select(:id).to_sql})
          )
        SQL
      )
    end
  end

  def down
    # no-op
  end
end
