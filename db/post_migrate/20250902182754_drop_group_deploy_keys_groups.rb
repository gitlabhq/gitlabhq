# frozen_string_literal: true

class DropGroupDeployKeysGroups < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    drop_table :group_deploy_keys_groups
  end

  def down
    execute <<~SQL
      CREATE TABLE group_deploy_keys_groups (
        id bigint NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        group_id bigint NOT NULL,
        group_deploy_key_id bigint NOT NULL,
        can_push boolean DEFAULT false NOT NULL
      );

      CREATE SEQUENCE group_deploy_keys_groups_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

      ALTER SEQUENCE group_deploy_keys_groups_id_seq OWNED BY group_deploy_keys_groups.id;

      ALTER TABLE ONLY group_deploy_keys_groups
        ALTER COLUMN id SET DEFAULT nextval('group_deploy_keys_groups_id_seq'::regclass);

      ALTER TABLE ONLY group_deploy_keys_groups
        ADD CONSTRAINT group_deploy_keys_groups_pkey PRIMARY KEY (id);

      CREATE UNIQUE INDEX index_group_deploy_keys_group_on_group_deploy_key_and_group_ids
        ON group_deploy_keys_groups USING btree (group_id, group_deploy_key_id);

      CREATE INDEX index_group_deploy_keys_groups_on_group_deploy_key_id
        ON group_deploy_keys_groups USING btree (group_deploy_key_id);
    SQL
  end
end
