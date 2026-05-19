# frozen_string_literal: true

class DropWorkItemTypes < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  TABLE_NAME = :work_item_types

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  def down
    # Recreate the table without a sequence on `id` to match the original schema
    # (IDs were statically assigned 1..9 by the BaseTypeImporter).
    execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
        id bigint NOT NULL PRIMARY KEY,
        base_type smallint DEFAULT 0 NOT NULL,
        cached_markdown_version integer,
        name text NOT NULL,
        description text,
        description_html text,
        icon_name text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        correct_id bigint DEFAULT 0 NOT NULL,
        old_id bigint,
        CONSTRAINT check_104d2410f6 CHECK ((char_length(name) <= 255)),
        CONSTRAINT check_fecb3a98d1 CHECK ((char_length(icon_name) <= 255))
      )
    SQL

    add_concurrent_index TABLE_NAME, [:base_type, :id],
      name: 'index_work_item_types_on_base_type_and_id'

    add_concurrent_index TABLE_NAME,
      'TRIM(BOTH FROM lower(name))',
      unique: true,
      name: 'index_work_item_types_on_name_unique'
  end
end
