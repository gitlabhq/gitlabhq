# frozen_string_literal: true

class RecreateWorkItemCustomTypesTable < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    execute(<<~SQL) # rubocop:disable Migration/DropTable -- We are recreating the table in the same transaction
      DROP TABLE work_item_custom_types;

      CREATE TABLE work_item_custom_types (
          id bigint NOT NULL,
          created_at timestamp with time zone NOT NULL,
          updated_at timestamp with time zone NOT NULL,
          organization_id bigint,
          namespace_id bigint,
          icon_name smallint DEFAULT 0 NOT NULL,
          converted_from_system_defined_type_identifier smallint,
          name text NOT NULL,
          CONSTRAINT check_1695e9567e CHECK ((id >= 1001)),
          CONSTRAINT check_26af0900e6 CHECK ((char_length(name) <= 48)),
          CONSTRAINT check_8d909174fb CHECK ((num_nonnulls(namespace_id, organization_id) = 1))
      );

      CREATE SEQUENCE work_item_custom_types_id_seq
          START WITH 1001
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE work_item_custom_types_id_seq OWNED BY work_item_custom_types.id;

      ALTER TABLE ONLY work_item_custom_types ALTER COLUMN id SET DEFAULT nextval('work_item_custom_types_id_seq'::regclass);

      ALTER TABLE ONLY work_item_custom_types
        ADD CONSTRAINT work_item_custom_types_pkey PRIMARY KEY (id);

      CREATE UNIQUE INDEX idx_work_item_custom_types_on_ns_id_and_name ON work_item_custom_types USING btree (namespace_id, lower(name)) WHERE (namespace_id IS NOT NULL);
      CREATE UNIQUE INDEX idx_work_item_custom_types_on_org_id_and_name ON work_item_custom_types USING btree (organization_id, lower(name)) WHERE (organization_id IS NOT NULL);
    SQL
  end

  def down
    execute(<<~SQL)
      ALTER SEQUENCE work_item_custom_types_id_seq START WITH 1;

      ALTER TABLE work_item_custom_types DROP CONSTRAINT check_1695e9567e;
    SQL
  end
end
