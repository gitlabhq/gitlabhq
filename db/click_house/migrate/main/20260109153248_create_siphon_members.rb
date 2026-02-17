# frozen_string_literal: true

class CreateSiphonMembers < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_members
      (
        id Int64,
        access_level Int64,
        source_id Int64,
        source_type String,
        user_id Nullable(Int64),
        notification_level Int64,
        type String,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        created_by_id Nullable(Int64),
        invite_email Nullable(String),
        invite_token Nullable(String),
        invite_accepted_at Nullable(DateTime64(6, 'UTC')),
        requested_at Nullable(DateTime64(6, 'UTC')),
        expires_at Nullable(Date32),
        ldap Bool DEFAULT false,
        override Bool DEFAULT false,
        state Int8 DEFAULT 0,
        invite_email_success Bool DEFAULT true,
        member_namespace_id Nullable(Int64),
        member_role_id Nullable(Int64),
        expiry_notified_at Nullable(DateTime64(6, 'UTC')),
        request_accepted_at Nullable(DateTime64(6, 'UTC')),
        traversal_path String DEFAULT multiIf(coalesce(member_namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', member_namespace_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_members
    SQL
  end
end
