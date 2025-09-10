# frozen_string_literal: true

class DropGroupDeployKeys < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    drop_table :group_deploy_keys
  end

  def down
    execute <<~SQL
      CREATE TABLE group_deploy_keys (
        id bigint NOT NULL,
        user_id bigint,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        last_used_at timestamp with time zone,
        expires_at timestamp with time zone,
        key text NOT NULL,
        title text,
        fingerprint text,
        fingerprint_sha256 bytea,
        CONSTRAINT check_cc0365908d CHECK ((char_length(title) <= 255)),
        CONSTRAINT check_e4526dcf91 CHECK ((char_length(fingerprint) <= 255)),
        CONSTRAINT check_f58fa0a0f7 CHECK ((char_length(key) <= 4096))
      );

      CREATE SEQUENCE group_deploy_keys_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

      ALTER SEQUENCE group_deploy_keys_id_seq OWNED BY group_deploy_keys.id;

      ALTER TABLE ONLY group_deploy_keys
        ALTER COLUMN id SET DEFAULT nextval('group_deploy_keys_id_seq'::regclass);

      ALTER TABLE ONLY group_deploy_keys
        ADD CONSTRAINT group_deploy_keys_pkey PRIMARY KEY (id);

      CREATE INDEX index_group_deploy_keys_on_fingerprint
        ON group_deploy_keys USING btree (fingerprint);

      CREATE UNIQUE INDEX index_group_deploy_keys_on_fingerprint_sha256_unique
        ON group_deploy_keys USING btree (fingerprint_sha256);

      CREATE INDEX index_group_deploy_keys_on_user_id
        ON group_deploy_keys USING btree (user_id);
    SQL
  end
end
