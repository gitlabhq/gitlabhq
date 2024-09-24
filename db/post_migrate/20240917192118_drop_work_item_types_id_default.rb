# frozen_string_literal: true

class DropWorkItemTypesIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    connection.execute(<<~SQL)
      ALTER TABLE work_item_types ALTER COLUMN id DROP DEFAULT;
    SQL
  end

  def down
    connection.execute(<<~SQL)
      ALTER TABLE work_item_types ALTER COLUMN id SET DEFAULT nextval('work_item_types_id_seq'::regclass);
    SQL
  end
end
