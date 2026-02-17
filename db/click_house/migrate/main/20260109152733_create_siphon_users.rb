# frozen_string_literal: true

class CreateSiphonUsers < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_users
      (
        id Int64,
        email String DEFAULT '',
        sign_in_count Int64 DEFAULT 0,
        current_sign_in_at Nullable(DateTime64(6, 'UTC')),
        last_sign_in_at Nullable(DateTime64(6, 'UTC')),
        current_sign_in_ip Nullable(String),
        last_sign_in_ip Nullable(String),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        name String DEFAULT '',
        admin Bool DEFAULT false,
        projects_limit Int64,
        failed_attempts Int64 DEFAULT 0,
        locked_at Nullable(DateTime64(6, 'UTC')),
        username String DEFAULT '',
        can_create_group Bool DEFAULT true,
        can_create_team Bool DEFAULT true,
        state String DEFAULT '',
        color_scheme_id Int64 DEFAULT 1,
        created_by_id Nullable(Int64),
        last_credential_check_at Nullable(DateTime64(6, 'UTC')),
        avatar Nullable(String),
        unconfirmed_email String DEFAULT '',
        hide_no_ssh_key Bool DEFAULT false,
        admin_email_unsubscribed_at Nullable(DateTime64(6, 'UTC')),
        notification_email Nullable(String),
        hide_no_password Bool DEFAULT false,
        password_automatically_set Bool DEFAULT false,
        public_email Nullable(String),
        dashboard Int64 DEFAULT 0,
        project_view Int64 DEFAULT 2,
        consumed_timestep Nullable(Int64),
        layout Int64 DEFAULT 0,
        hide_project_limit Bool DEFAULT false,
        note Nullable(String),
        otp_grace_period_started_at Nullable(DateTime64(6, 'UTC')),
        external Bool DEFAULT false,
        auditor Bool DEFAULT false,
        require_two_factor_authentication_from_group Bool DEFAULT false,
        two_factor_grace_period Int64 DEFAULT 48,
        last_activity_on Nullable(Date32),
        notified_of_own_activity Nullable(Bool) DEFAULT false,
        preferred_language Nullable(String),
        theme_id Nullable(Int8),
        accepted_term_id Nullable(Int64),
        private_profile Bool DEFAULT false,
        roadmap_layout Nullable(Int8),
        include_private_contributions Nullable(Bool),
        commit_email Nullable(String),
        group_view Nullable(Int64),
        managing_group_id Nullable(Int64),
        first_name String DEFAULT '',
        last_name String DEFAULT '',
        user_type Int8 DEFAULT 0,
        onboarding_in_progress Bool DEFAULT false,
        color_mode_id Int8 DEFAULT 1,
        composite_identity_enforced Bool DEFAULT false,
        organization_id Int64,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_users
    SQL
  end
end
