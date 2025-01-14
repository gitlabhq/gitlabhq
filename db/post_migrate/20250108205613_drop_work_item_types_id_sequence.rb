# frozen_string_literal: true

class DropWorkItemTypesIdSequence < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def up
    connection.execute(<<~SQL)
      DROP SEQUENCE IF EXISTS work_item_types_id_seq CASCADE;
    SQL
  end

  def down
    # In https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166678 we stopped using the sequence
    # So it's safe to rollback and use START WITH 1 instead of fetching the actual latest value for the
    # work_item_types.id column
    connection.execute(<<~SQL)
      CREATE SEQUENCE work_item_types_id_seq
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1;

      ALTER SEQUENCE work_item_types_id_seq OWNED BY work_item_types.id;
    SQL
  end
end
