SET search_path=public;

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

CREATE TABLE public.abuse_reports (
    id integer NOT NULL,
    reporter_id integer,
    user_id integer,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_html text,
    cached_markdown_version integer
);

CREATE SEQUENCE public.abuse_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.abuse_reports_id_seq OWNED BY public.abuse_reports.id;

CREATE TABLE public.alert_management_alert_assignees (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    alert_id bigint NOT NULL
);

CREATE SEQUENCE public.alert_management_alert_assignees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.alert_management_alert_assignees_id_seq OWNED BY public.alert_management_alert_assignees.id;

CREATE TABLE public.alert_management_alert_user_mentions (
    id bigint NOT NULL,
    alert_management_alert_id bigint NOT NULL,
    note_id bigint,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.alert_management_alert_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.alert_management_alert_user_mentions_id_seq OWNED BY public.alert_management_alert_user_mentions.id;

CREATE TABLE public.alert_management_alerts (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    events integer DEFAULT 1 NOT NULL,
    iid integer NOT NULL,
    severity smallint DEFAULT 0 NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    fingerprint bytea,
    issue_id bigint,
    project_id bigint NOT NULL,
    title text NOT NULL,
    description text,
    service text,
    monitoring_tool text,
    hosts text[] DEFAULT '{}'::text[] NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT check_2df3e2fdc1 CHECK ((char_length(monitoring_tool) <= 100)),
    CONSTRAINT check_5e9e57cadb CHECK ((char_length(description) <= 1000)),
    CONSTRAINT check_bac14dddde CHECK ((char_length(service) <= 100)),
    CONSTRAINT check_d1d1c2d14c CHECK ((char_length(title) <= 200))
);

CREATE SEQUENCE public.alert_management_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.alert_management_alerts_id_seq OWNED BY public.alert_management_alerts.id;

CREATE TABLE public.alerts_service_data (
    id bigint NOT NULL,
    service_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_token character varying(255),
    encrypted_token_iv character varying(255)
);

CREATE SEQUENCE public.alerts_service_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.alerts_service_data_id_seq OWNED BY public.alerts_service_data.id;

CREATE TABLE public.allowed_email_domains (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    group_id integer NOT NULL,
    domain character varying(255) NOT NULL
);

CREATE SEQUENCE public.allowed_email_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.allowed_email_domains_id_seq OWNED BY public.allowed_email_domains.id;

CREATE TABLE public.analytics_cycle_analytics_group_stages (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    relative_position integer,
    start_event_identifier integer NOT NULL,
    end_event_identifier integer NOT NULL,
    group_id bigint NOT NULL,
    start_event_label_id bigint,
    end_event_label_id bigint,
    hidden boolean DEFAULT false NOT NULL,
    custom boolean DEFAULT true NOT NULL,
    name character varying(255) NOT NULL
);

CREATE SEQUENCE public.analytics_cycle_analytics_group_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.analytics_cycle_analytics_group_stages_id_seq OWNED BY public.analytics_cycle_analytics_group_stages.id;

CREATE TABLE public.analytics_cycle_analytics_project_stages (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    relative_position integer,
    start_event_identifier integer NOT NULL,
    end_event_identifier integer NOT NULL,
    project_id bigint NOT NULL,
    start_event_label_id bigint,
    end_event_label_id bigint,
    hidden boolean DEFAULT false NOT NULL,
    custom boolean DEFAULT true NOT NULL,
    name character varying(255) NOT NULL
);

CREATE SEQUENCE public.analytics_cycle_analytics_project_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.analytics_cycle_analytics_project_stages_id_seq OWNED BY public.analytics_cycle_analytics_project_stages.id;

CREATE TABLE public.analytics_language_trend_repository_languages (
    file_count integer DEFAULT 0 NOT NULL,
    programming_language_id bigint NOT NULL,
    project_id bigint NOT NULL,
    loc integer DEFAULT 0 NOT NULL,
    bytes integer DEFAULT 0 NOT NULL,
    percentage smallint DEFAULT 0 NOT NULL,
    snapshot_date date NOT NULL
);

CREATE TABLE public.appearances (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    logo character varying,
    updated_by integer,
    header_logo character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    description_html text,
    cached_markdown_version integer,
    new_project_guidelines text,
    new_project_guidelines_html text,
    header_message text,
    header_message_html text,
    footer_message text,
    footer_message_html text,
    message_background_color text,
    message_font_color text,
    favicon character varying,
    email_header_and_footer_enabled boolean DEFAULT false NOT NULL,
    profile_image_guidelines text,
    profile_image_guidelines_html text,
    CONSTRAINT appearances_profile_image_guidelines CHECK ((char_length(profile_image_guidelines) <= 4096))
);

CREATE SEQUENCE public.appearances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.appearances_id_seq OWNED BY public.appearances.id;

CREATE TABLE public.application_setting_terms (
    id integer NOT NULL,
    cached_markdown_version integer,
    terms text NOT NULL,
    terms_html text
);

CREATE SEQUENCE public.application_setting_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.application_setting_terms_id_seq OWNED BY public.application_setting_terms.id;

CREATE TABLE public.application_settings (
    id integer NOT NULL,
    default_projects_limit integer,
    signup_enabled boolean,
    gravatar_enabled boolean,
    sign_in_text text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    home_page_url character varying,
    default_branch_protection integer DEFAULT 2,
    help_text text,
    restricted_visibility_levels text,
    version_check_enabled boolean DEFAULT true,
    max_attachment_size integer DEFAULT 10 NOT NULL,
    default_project_visibility integer DEFAULT 0 NOT NULL,
    default_snippet_visibility integer DEFAULT 0 NOT NULL,
    domain_whitelist text,
    user_oauth_applications boolean DEFAULT true,
    after_sign_out_path character varying,
    session_expire_delay integer DEFAULT 10080 NOT NULL,
    import_sources text,
    help_page_text text,
    admin_notification_email character varying,
    shared_runners_enabled boolean DEFAULT true NOT NULL,
    max_artifacts_size integer DEFAULT 100 NOT NULL,
    runners_registration_token character varying,
    max_pages_size integer DEFAULT 100 NOT NULL,
    require_two_factor_authentication boolean DEFAULT false,
    two_factor_grace_period integer DEFAULT 48,
    metrics_enabled boolean DEFAULT false,
    metrics_host character varying DEFAULT 'localhost'::character varying,
    metrics_pool_size integer DEFAULT 16,
    metrics_timeout integer DEFAULT 10,
    metrics_method_call_threshold integer DEFAULT 10,
    recaptcha_enabled boolean DEFAULT false,
    metrics_port integer DEFAULT 8089,
    akismet_enabled boolean DEFAULT false,
    metrics_sample_interval integer DEFAULT 15,
    email_author_in_body boolean DEFAULT false,
    default_group_visibility integer,
    repository_checks_enabled boolean DEFAULT false,
    shared_runners_text text,
    metrics_packet_size integer DEFAULT 1,
    disabled_oauth_sign_in_sources text,
    health_check_access_token character varying,
    send_user_confirmation_email boolean DEFAULT false,
    container_registry_token_expire_delay integer DEFAULT 5,
    after_sign_up_text text,
    user_default_external boolean DEFAULT false NOT NULL,
    elasticsearch_indexing boolean DEFAULT false NOT NULL,
    elasticsearch_search boolean DEFAULT false NOT NULL,
    repository_storages character varying DEFAULT 'default'::character varying,
    enabled_git_access_protocol character varying,
    domain_blacklist_enabled boolean DEFAULT false,
    domain_blacklist text,
    usage_ping_enabled boolean DEFAULT true NOT NULL,
    sign_in_text_html text,
    help_page_text_html text,
    shared_runners_text_html text,
    after_sign_up_text_html text,
    rsa_key_restriction integer DEFAULT 0 NOT NULL,
    dsa_key_restriction integer DEFAULT '-1'::integer NOT NULL,
    ecdsa_key_restriction integer DEFAULT 0 NOT NULL,
    ed25519_key_restriction integer DEFAULT 0 NOT NULL,
    housekeeping_enabled boolean DEFAULT true NOT NULL,
    housekeeping_bitmaps_enabled boolean DEFAULT true NOT NULL,
    housekeeping_incremental_repack_period integer DEFAULT 10 NOT NULL,
    housekeeping_full_repack_period integer DEFAULT 50 NOT NULL,
    housekeeping_gc_period integer DEFAULT 200 NOT NULL,
    html_emails_enabled boolean DEFAULT true,
    plantuml_url character varying,
    plantuml_enabled boolean,
    shared_runners_minutes integer DEFAULT 0 NOT NULL,
    repository_size_limit bigint DEFAULT 0,
    terminal_max_session_time integer DEFAULT 0 NOT NULL,
    unique_ips_limit_per_user integer,
    unique_ips_limit_time_window integer,
    unique_ips_limit_enabled boolean DEFAULT false NOT NULL,
    default_artifacts_expire_in character varying DEFAULT '0'::character varying NOT NULL,
    elasticsearch_url character varying DEFAULT 'http://localhost:9200'::character varying,
    elasticsearch_aws boolean DEFAULT false NOT NULL,
    elasticsearch_aws_region character varying DEFAULT 'us-east-1'::character varying,
    elasticsearch_aws_access_key character varying,
    geo_status_timeout integer DEFAULT 10,
    uuid character varying,
    polling_interval_multiplier numeric DEFAULT 1.0 NOT NULL,
    cached_markdown_version integer,
    check_namespace_plan boolean DEFAULT false NOT NULL,
    mirror_max_delay integer DEFAULT 300 NOT NULL,
    mirror_max_capacity integer DEFAULT 100 NOT NULL,
    mirror_capacity_threshold integer DEFAULT 50 NOT NULL,
    prometheus_metrics_enabled boolean DEFAULT true NOT NULL,
    authorized_keys_enabled boolean DEFAULT true NOT NULL,
    help_page_hide_commercial_content boolean DEFAULT false,
    help_page_support_url character varying,
    slack_app_enabled boolean DEFAULT false,
    slack_app_id character varying,
    performance_bar_allowed_group_id integer,
    allow_group_owners_to_manage_ldap boolean DEFAULT true NOT NULL,
    hashed_storage_enabled boolean DEFAULT true NOT NULL,
    project_export_enabled boolean DEFAULT true NOT NULL,
    auto_devops_enabled boolean DEFAULT true NOT NULL,
    throttle_unauthenticated_enabled boolean DEFAULT false NOT NULL,
    throttle_unauthenticated_requests_per_period integer DEFAULT 3600 NOT NULL,
    throttle_unauthenticated_period_in_seconds integer DEFAULT 3600 NOT NULL,
    throttle_authenticated_api_enabled boolean DEFAULT false NOT NULL,
    throttle_authenticated_api_requests_per_period integer DEFAULT 7200 NOT NULL,
    throttle_authenticated_api_period_in_seconds integer DEFAULT 3600 NOT NULL,
    throttle_authenticated_web_enabled boolean DEFAULT false NOT NULL,
    throttle_authenticated_web_requests_per_period integer DEFAULT 7200 NOT NULL,
    throttle_authenticated_web_period_in_seconds integer DEFAULT 3600 NOT NULL,
    gitaly_timeout_default integer DEFAULT 55 NOT NULL,
    gitaly_timeout_medium integer DEFAULT 30 NOT NULL,
    gitaly_timeout_fast integer DEFAULT 10 NOT NULL,
    mirror_available boolean DEFAULT true NOT NULL,
    password_authentication_enabled_for_web boolean,
    password_authentication_enabled_for_git boolean DEFAULT true NOT NULL,
    auto_devops_domain character varying,
    external_authorization_service_enabled boolean DEFAULT false NOT NULL,
    external_authorization_service_url character varying,
    external_authorization_service_default_label character varying,
    pages_domain_verification_enabled boolean DEFAULT true NOT NULL,
    user_default_internal_regex character varying,
    external_authorization_service_timeout double precision DEFAULT 0.5,
    external_auth_client_cert text,
    encrypted_external_auth_client_key text,
    encrypted_external_auth_client_key_iv character varying,
    encrypted_external_auth_client_key_pass character varying,
    encrypted_external_auth_client_key_pass_iv character varying,
    email_additional_text character varying,
    enforce_terms boolean DEFAULT false,
    file_template_project_id integer,
    pseudonymizer_enabled boolean DEFAULT false NOT NULL,
    hide_third_party_offers boolean DEFAULT false NOT NULL,
    snowplow_enabled boolean DEFAULT false NOT NULL,
    snowplow_collector_hostname character varying,
    snowplow_cookie_domain character varying,
    instance_statistics_visibility_private boolean DEFAULT false NOT NULL,
    web_ide_clientside_preview_enabled boolean DEFAULT false NOT NULL,
    user_show_add_ssh_key_message boolean DEFAULT true NOT NULL,
    custom_project_templates_group_id integer,
    usage_stats_set_by_user_id integer,
    receive_max_input_size integer,
    diff_max_patch_bytes integer DEFAULT 102400 NOT NULL,
    archive_builds_in_seconds integer,
    commit_email_hostname character varying,
    protected_ci_variables boolean DEFAULT true NOT NULL,
    runners_registration_token_encrypted character varying,
    local_markdown_version integer DEFAULT 0 NOT NULL,
    first_day_of_week integer DEFAULT 0 NOT NULL,
    elasticsearch_limit_indexing boolean DEFAULT false NOT NULL,
    default_project_creation integer DEFAULT 2 NOT NULL,
    lets_encrypt_notification_email character varying,
    lets_encrypt_terms_of_service_accepted boolean DEFAULT false NOT NULL,
    geo_node_allowed_ips character varying DEFAULT '0.0.0.0/0, ::/0'::character varying,
    elasticsearch_shards integer DEFAULT 5 NOT NULL,
    elasticsearch_replicas integer DEFAULT 1 NOT NULL,
    encrypted_lets_encrypt_private_key text,
    encrypted_lets_encrypt_private_key_iv text,
    required_instance_ci_template character varying,
    dns_rebinding_protection_enabled boolean DEFAULT true NOT NULL,
    default_project_deletion_protection boolean DEFAULT false NOT NULL,
    grafana_enabled boolean DEFAULT false NOT NULL,
    lock_memberships_to_ldap boolean DEFAULT false NOT NULL,
    time_tracking_limit_to_hours boolean DEFAULT false NOT NULL,
    grafana_url character varying DEFAULT '/-/grafana'::character varying NOT NULL,
    login_recaptcha_protection_enabled boolean DEFAULT false NOT NULL,
    outbound_local_requests_whitelist character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    raw_blob_request_limit integer DEFAULT 300 NOT NULL,
    allow_local_requests_from_web_hooks_and_services boolean DEFAULT false NOT NULL,
    allow_local_requests_from_system_hooks boolean DEFAULT true NOT NULL,
    instance_administration_project_id bigint,
    asset_proxy_enabled boolean DEFAULT false NOT NULL,
    asset_proxy_url character varying,
    asset_proxy_whitelist text,
    encrypted_asset_proxy_secret_key text,
    encrypted_asset_proxy_secret_key_iv character varying,
    static_objects_external_storage_url character varying(255),
    static_objects_external_storage_auth_token character varying(255),
    max_personal_access_token_lifetime integer,
    throttle_protected_paths_enabled boolean DEFAULT false NOT NULL,
    throttle_protected_paths_requests_per_period integer DEFAULT 10 NOT NULL,
    throttle_protected_paths_period_in_seconds integer DEFAULT 60 NOT NULL,
    protected_paths character varying(255)[] DEFAULT '{/users/password,/users/sign_in,/api/v3/session.json,/api/v3/session,/api/v4/session.json,/api/v4/session,/users,/users/confirmation,/unsubscribes/,/import/github/personal_access_token,/admin/session}'::character varying[],
    throttle_incident_management_notification_enabled boolean DEFAULT false NOT NULL,
    throttle_incident_management_notification_period_in_seconds integer DEFAULT 3600,
    throttle_incident_management_notification_per_period integer DEFAULT 3600,
    snowplow_iglu_registry_url character varying(255),
    push_event_hooks_limit integer DEFAULT 3 NOT NULL,
    push_event_activities_limit integer DEFAULT 3 NOT NULL,
    custom_http_clone_url_root character varying(511),
    deletion_adjourned_period integer DEFAULT 7 NOT NULL,
    license_trial_ends_on date,
    eks_integration_enabled boolean DEFAULT false NOT NULL,
    eks_account_id character varying(128),
    eks_access_key_id character varying(128),
    encrypted_eks_secret_access_key_iv character varying(255),
    encrypted_eks_secret_access_key text,
    snowplow_app_id character varying,
    productivity_analytics_start_date timestamp with time zone,
    default_ci_config_path character varying(255),
    sourcegraph_enabled boolean DEFAULT false NOT NULL,
    sourcegraph_url character varying(255),
    sourcegraph_public_only boolean DEFAULT true NOT NULL,
    snippet_size_limit bigint DEFAULT 52428800 NOT NULL,
    minimum_password_length integer DEFAULT 8 NOT NULL,
    encrypted_akismet_api_key text,
    encrypted_akismet_api_key_iv character varying(255),
    encrypted_elasticsearch_aws_secret_access_key text,
    encrypted_elasticsearch_aws_secret_access_key_iv character varying(255),
    encrypted_recaptcha_private_key text,
    encrypted_recaptcha_private_key_iv character varying(255),
    encrypted_recaptcha_site_key text,
    encrypted_recaptcha_site_key_iv character varying(255),
    encrypted_slack_app_secret text,
    encrypted_slack_app_secret_iv character varying(255),
    encrypted_slack_app_verification_token text,
    encrypted_slack_app_verification_token_iv character varying(255),
    force_pages_access_control boolean DEFAULT false NOT NULL,
    updating_name_disabled_for_users boolean DEFAULT false NOT NULL,
    instance_administrators_group_id integer,
    elasticsearch_indexed_field_length_limit integer DEFAULT 0 NOT NULL,
    elasticsearch_max_bulk_size_mb smallint DEFAULT 10 NOT NULL,
    elasticsearch_max_bulk_concurrency smallint DEFAULT 10 NOT NULL,
    disable_overriding_approvers_per_merge_request boolean DEFAULT false NOT NULL,
    prevent_merge_requests_author_approval boolean DEFAULT false NOT NULL,
    prevent_merge_requests_committers_approval boolean DEFAULT false NOT NULL,
    email_restrictions_enabled boolean DEFAULT false NOT NULL,
    email_restrictions text,
    npm_package_requests_forwarding boolean DEFAULT true NOT NULL,
    namespace_storage_size_limit bigint DEFAULT 0 NOT NULL,
    seat_link_enabled boolean DEFAULT true NOT NULL,
    container_expiration_policies_enable_historic_entries boolean DEFAULT false NOT NULL,
    issues_create_limit integer DEFAULT 300 NOT NULL,
    push_rule_id bigint,
    group_owners_can_manage_default_branch_protection boolean DEFAULT true NOT NULL,
    container_registry_vendor text DEFAULT ''::text NOT NULL,
    container_registry_version text DEFAULT ''::text NOT NULL,
    container_registry_features text[] DEFAULT '{}'::text[] NOT NULL,
    spam_check_endpoint_url text,
    spam_check_endpoint_enabled boolean DEFAULT false NOT NULL,
    elasticsearch_pause_indexing boolean DEFAULT false NOT NULL,
    repository_storages_weighted jsonb DEFAULT '{}'::jsonb NOT NULL,
    max_import_size integer DEFAULT 50 NOT NULL,
    enforce_pat_expiration boolean DEFAULT true NOT NULL,
    CONSTRAINT check_d03919528d CHECK ((char_length(container_registry_vendor) <= 255)),
    CONSTRAINT check_d820146492 CHECK ((char_length(spam_check_endpoint_url) <= 255)),
    CONSTRAINT check_e5aba18f02 CHECK ((char_length(container_registry_version) <= 255))
);

CREATE SEQUENCE public.application_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.application_settings_id_seq OWNED BY public.application_settings.id;

CREATE TABLE public.approval_merge_request_rule_sources (
    id bigint NOT NULL,
    approval_merge_request_rule_id bigint NOT NULL,
    approval_project_rule_id bigint NOT NULL
);

CREATE SEQUENCE public.approval_merge_request_rule_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_merge_request_rule_sources_id_seq OWNED BY public.approval_merge_request_rule_sources.id;

CREATE TABLE public.approval_merge_request_rules (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    merge_request_id integer NOT NULL,
    approvals_required smallint DEFAULT 0 NOT NULL,
    code_owner boolean DEFAULT false NOT NULL,
    name character varying NOT NULL,
    rule_type smallint DEFAULT 1 NOT NULL,
    report_type smallint,
    section text,
    CONSTRAINT check_6fca5928b2 CHECK ((char_length(section) <= 255))
);

CREATE TABLE public.approval_merge_request_rules_approved_approvers (
    id bigint NOT NULL,
    approval_merge_request_rule_id bigint NOT NULL,
    user_id integer NOT NULL
);

CREATE SEQUENCE public.approval_merge_request_rules_approved_approvers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_merge_request_rules_approved_approvers_id_seq OWNED BY public.approval_merge_request_rules_approved_approvers.id;

CREATE TABLE public.approval_merge_request_rules_groups (
    id bigint NOT NULL,
    approval_merge_request_rule_id bigint NOT NULL,
    group_id integer NOT NULL
);

CREATE SEQUENCE public.approval_merge_request_rules_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_merge_request_rules_groups_id_seq OWNED BY public.approval_merge_request_rules_groups.id;

CREATE SEQUENCE public.approval_merge_request_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_merge_request_rules_id_seq OWNED BY public.approval_merge_request_rules.id;

CREATE TABLE public.approval_merge_request_rules_users (
    id bigint NOT NULL,
    approval_merge_request_rule_id bigint NOT NULL,
    user_id integer NOT NULL
);

CREATE SEQUENCE public.approval_merge_request_rules_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_merge_request_rules_users_id_seq OWNED BY public.approval_merge_request_rules_users.id;

CREATE TABLE public.approval_project_rules (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    approvals_required smallint DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    rule_type smallint DEFAULT 0 NOT NULL
);

CREATE TABLE public.approval_project_rules_groups (
    id bigint NOT NULL,
    approval_project_rule_id bigint NOT NULL,
    group_id integer NOT NULL
);

CREATE SEQUENCE public.approval_project_rules_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_project_rules_groups_id_seq OWNED BY public.approval_project_rules_groups.id;

CREATE SEQUENCE public.approval_project_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_project_rules_id_seq OWNED BY public.approval_project_rules.id;

CREATE TABLE public.approval_project_rules_protected_branches (
    approval_project_rule_id bigint NOT NULL,
    protected_branch_id bigint NOT NULL
);

CREATE TABLE public.approval_project_rules_users (
    id bigint NOT NULL,
    approval_project_rule_id bigint NOT NULL,
    user_id integer NOT NULL
);

CREATE SEQUENCE public.approval_project_rules_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approval_project_rules_users_id_seq OWNED BY public.approval_project_rules_users.id;

CREATE TABLE public.approvals (
    id integer NOT NULL,
    merge_request_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.approvals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approvals_id_seq OWNED BY public.approvals.id;

CREATE TABLE public.approver_groups (
    id integer NOT NULL,
    target_id integer NOT NULL,
    target_type character varying NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.approver_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approver_groups_id_seq OWNED BY public.approver_groups.id;

CREATE TABLE public.approvers (
    id integer NOT NULL,
    target_id integer NOT NULL,
    target_type character varying,
    user_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.approvers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approvers_id_seq OWNED BY public.approvers.id;

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE public.audit_events (
    id integer NOT NULL,
    author_id integer NOT NULL,
    type character varying NOT NULL,
    entity_id integer NOT NULL,
    entity_type character varying NOT NULL,
    details text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.audit_events_id_seq OWNED BY public.audit_events.id;

CREATE TABLE public.award_emoji (
    id integer NOT NULL,
    name character varying,
    user_id integer,
    awardable_id integer,
    awardable_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.award_emoji_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.award_emoji_id_seq OWNED BY public.award_emoji.id;

CREATE TABLE public.aws_roles (
    user_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    role_arn character varying(2048) NOT NULL,
    role_external_id character varying(64) NOT NULL
);

CREATE TABLE public.badges (
    id integer NOT NULL,
    link_url character varying NOT NULL,
    image_url character varying NOT NULL,
    project_id integer,
    group_id integer,
    type character varying NOT NULL,
    name character varying(255),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.badges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.badges_id_seq OWNED BY public.badges.id;

CREATE TABLE public.board_assignees (
    id integer NOT NULL,
    board_id integer NOT NULL,
    assignee_id integer NOT NULL
);

CREATE SEQUENCE public.board_assignees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.board_assignees_id_seq OWNED BY public.board_assignees.id;

CREATE TABLE public.board_group_recent_visits (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer,
    board_id integer,
    group_id integer
);

CREATE SEQUENCE public.board_group_recent_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.board_group_recent_visits_id_seq OWNED BY public.board_group_recent_visits.id;

CREATE TABLE public.board_labels (
    id integer NOT NULL,
    board_id integer NOT NULL,
    label_id integer NOT NULL
);

CREATE SEQUENCE public.board_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.board_labels_id_seq OWNED BY public.board_labels.id;

CREATE TABLE public.board_project_recent_visits (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer,
    project_id integer,
    board_id integer
);

CREATE SEQUENCE public.board_project_recent_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.board_project_recent_visits_id_seq OWNED BY public.board_project_recent_visits.id;

CREATE TABLE public.board_user_preferences (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    board_id bigint NOT NULL,
    hide_labels boolean,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.board_user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.board_user_preferences_id_seq OWNED BY public.board_user_preferences.id;

CREATE TABLE public.boards (
    id integer NOT NULL,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying DEFAULT 'Development'::character varying NOT NULL,
    milestone_id integer,
    group_id integer,
    weight integer
);

CREATE SEQUENCE public.boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.boards_id_seq OWNED BY public.boards.id;

CREATE TABLE public.broadcast_messages (
    id integer NOT NULL,
    message text NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    color character varying,
    font character varying,
    message_html text NOT NULL,
    cached_markdown_version integer,
    target_path character varying(255),
    broadcast_type smallint DEFAULT 1 NOT NULL,
    dismissable boolean
);

CREATE SEQUENCE public.broadcast_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.broadcast_messages_id_seq OWNED BY public.broadcast_messages.id;

CREATE TABLE public.chat_names (
    id integer NOT NULL,
    user_id integer NOT NULL,
    service_id integer NOT NULL,
    team_id character varying NOT NULL,
    team_domain character varying,
    chat_id character varying NOT NULL,
    chat_name character varying,
    last_used_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.chat_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.chat_names_id_seq OWNED BY public.chat_names.id;

CREATE TABLE public.chat_teams (
    id integer NOT NULL,
    namespace_id integer NOT NULL,
    team_id character varying,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.chat_teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.chat_teams_id_seq OWNED BY public.chat_teams.id;

CREATE TABLE public.ci_build_needs (
    id integer NOT NULL,
    build_id integer NOT NULL,
    name text NOT NULL,
    artifacts boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.ci_build_needs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_build_needs_id_seq OWNED BY public.ci_build_needs.id;

CREATE TABLE public.ci_build_report_results (
    build_id bigint NOT NULL,
    project_id bigint NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE SEQUENCE public.ci_build_report_results_build_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_build_report_results_build_id_seq OWNED BY public.ci_build_report_results.build_id;

CREATE TABLE public.ci_build_trace_chunks (
    id bigint NOT NULL,
    build_id integer NOT NULL,
    chunk_index integer NOT NULL,
    data_store integer NOT NULL,
    raw_data bytea
);

CREATE SEQUENCE public.ci_build_trace_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_build_trace_chunks_id_seq OWNED BY public.ci_build_trace_chunks.id;

CREATE TABLE public.ci_build_trace_section_names (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name character varying NOT NULL
);

CREATE SEQUENCE public.ci_build_trace_section_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_build_trace_section_names_id_seq OWNED BY public.ci_build_trace_section_names.id;

CREATE TABLE public.ci_build_trace_sections (
    project_id integer NOT NULL,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone NOT NULL,
    byte_start bigint NOT NULL,
    byte_end bigint NOT NULL,
    build_id integer NOT NULL,
    section_name_id integer NOT NULL
);

CREATE TABLE public.ci_builds (
    id integer NOT NULL,
    status character varying,
    finished_at timestamp without time zone,
    trace text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    started_at timestamp without time zone,
    runner_id integer,
    coverage double precision,
    commit_id integer,
    commands text,
    name character varying,
    options text,
    allow_failure boolean DEFAULT false NOT NULL,
    stage character varying,
    trigger_request_id integer,
    stage_idx integer,
    tag boolean,
    ref character varying,
    user_id integer,
    type character varying,
    target_url character varying,
    description character varying,
    artifacts_file text,
    project_id integer,
    artifacts_metadata text,
    erased_by_id integer,
    erased_at timestamp without time zone,
    artifacts_expire_at timestamp without time zone,
    environment character varying,
    artifacts_size bigint,
    "when" character varying,
    yaml_variables text,
    queued_at timestamp without time zone,
    token character varying,
    lock_version integer DEFAULT 0,
    coverage_regex character varying,
    auto_canceled_by_id integer,
    retried boolean,
    stage_id integer,
    artifacts_file_store integer,
    artifacts_metadata_store integer,
    protected boolean,
    failure_reason integer,
    scheduled_at timestamp with time zone,
    token_encrypted character varying,
    upstream_pipeline_id integer,
    resource_group_id bigint,
    waiting_for_resource_at timestamp with time zone,
    processed boolean,
    scheduling_type smallint
);

CREATE SEQUENCE public.ci_builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_builds_id_seq OWNED BY public.ci_builds.id;

CREATE TABLE public.ci_builds_metadata (
    id integer NOT NULL,
    build_id integer NOT NULL,
    project_id integer NOT NULL,
    timeout integer,
    timeout_source integer DEFAULT 1 NOT NULL,
    interruptible boolean,
    config_options jsonb,
    config_variables jsonb,
    has_exposed_artifacts boolean,
    environment_auto_stop_in character varying(255),
    expanded_environment_name character varying(255)
);

CREATE SEQUENCE public.ci_builds_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_builds_metadata_id_seq OWNED BY public.ci_builds_metadata.id;

CREATE TABLE public.ci_builds_runner_session (
    id bigint NOT NULL,
    build_id integer NOT NULL,
    url character varying NOT NULL,
    certificate character varying,
    "authorization" character varying
);

CREATE SEQUENCE public.ci_builds_runner_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_builds_runner_session_id_seq OWNED BY public.ci_builds_runner_session.id;

CREATE TABLE public.ci_daily_build_group_report_results (
    id bigint NOT NULL,
    date date NOT NULL,
    project_id bigint NOT NULL,
    last_pipeline_id bigint NOT NULL,
    ref_path text NOT NULL,
    group_name text NOT NULL,
    data jsonb NOT NULL
);

CREATE SEQUENCE public.ci_daily_build_group_report_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_daily_build_group_report_results_id_seq OWNED BY public.ci_daily_build_group_report_results.id;

CREATE TABLE public.ci_daily_report_results (
    id bigint NOT NULL,
    date date NOT NULL,
    project_id bigint NOT NULL,
    last_pipeline_id bigint NOT NULL,
    value double precision NOT NULL,
    param_type bigint NOT NULL,
    ref_path character varying NOT NULL,
    title character varying NOT NULL
);

CREATE SEQUENCE public.ci_daily_report_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_daily_report_results_id_seq OWNED BY public.ci_daily_report_results.id;

CREATE TABLE public.ci_freeze_periods (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    freeze_start character varying(998) NOT NULL,
    freeze_end character varying(998) NOT NULL,
    cron_timezone character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.ci_freeze_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_freeze_periods_id_seq OWNED BY public.ci_freeze_periods.id;

CREATE TABLE public.ci_group_variables (
    id integer NOT NULL,
    key character varying NOT NULL,
    value text,
    encrypted_value text,
    encrypted_value_salt character varying,
    encrypted_value_iv character varying,
    group_id integer NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    masked boolean DEFAULT false NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL
);

CREATE SEQUENCE public.ci_group_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_group_variables_id_seq OWNED BY public.ci_group_variables.id;

CREATE TABLE public.ci_instance_variables (
    id bigint NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL,
    masked boolean DEFAULT false,
    protected boolean DEFAULT false,
    key text NOT NULL,
    encrypted_value text,
    encrypted_value_iv text,
    CONSTRAINT check_07a45a5bcb CHECK ((char_length(encrypted_value_iv) <= 255)),
    CONSTRAINT check_5aede12208 CHECK ((char_length(key) <= 255)),
    CONSTRAINT check_5ebd0515a0 CHECK ((char_length(encrypted_value) <= 1024))
);

CREATE SEQUENCE public.ci_instance_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_instance_variables_id_seq OWNED BY public.ci_instance_variables.id;

CREATE TABLE public.ci_job_artifacts (
    id integer NOT NULL,
    project_id integer NOT NULL,
    job_id integer NOT NULL,
    file_type integer NOT NULL,
    size bigint,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    expire_at timestamp with time zone,
    file character varying,
    file_store integer DEFAULT 1,
    file_sha256 bytea,
    file_format smallint,
    file_location smallint,
    locked boolean
);

CREATE SEQUENCE public.ci_job_artifacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_job_artifacts_id_seq OWNED BY public.ci_job_artifacts.id;

CREATE TABLE public.ci_job_variables (
    id bigint NOT NULL,
    key character varying NOT NULL,
    encrypted_value text,
    encrypted_value_iv character varying,
    job_id bigint NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL,
    source smallint DEFAULT 0 NOT NULL
);

CREATE SEQUENCE public.ci_job_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_job_variables_id_seq OWNED BY public.ci_job_variables.id;

CREATE TABLE public.ci_pipeline_chat_data (
    id bigint NOT NULL,
    pipeline_id integer NOT NULL,
    chat_name_id integer NOT NULL,
    response_url text NOT NULL
);

CREATE SEQUENCE public.ci_pipeline_chat_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_pipeline_chat_data_id_seq OWNED BY public.ci_pipeline_chat_data.id;

CREATE TABLE public.ci_pipeline_schedule_variables (
    id integer NOT NULL,
    key character varying NOT NULL,
    value text,
    encrypted_value text,
    encrypted_value_salt character varying,
    encrypted_value_iv character varying,
    pipeline_schedule_id integer NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    variable_type smallint DEFAULT 1 NOT NULL
);

CREATE SEQUENCE public.ci_pipeline_schedule_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_pipeline_schedule_variables_id_seq OWNED BY public.ci_pipeline_schedule_variables.id;

CREATE TABLE public.ci_pipeline_schedules (
    id integer NOT NULL,
    description character varying,
    ref character varying,
    cron character varying,
    cron_timezone character varying,
    next_run_at timestamp without time zone,
    project_id integer,
    owner_id integer,
    active boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.ci_pipeline_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_pipeline_schedules_id_seq OWNED BY public.ci_pipeline_schedules.id;

CREATE TABLE public.ci_pipeline_variables (
    id integer NOT NULL,
    key character varying NOT NULL,
    value text,
    encrypted_value text,
    encrypted_value_salt character varying,
    encrypted_value_iv character varying,
    pipeline_id integer NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL
);

CREATE SEQUENCE public.ci_pipeline_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_pipeline_variables_id_seq OWNED BY public.ci_pipeline_variables.id;

CREATE TABLE public.ci_pipelines (
    id integer NOT NULL,
    ref character varying,
    sha character varying,
    before_sha character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tag boolean DEFAULT false,
    yaml_errors text,
    committed_at timestamp without time zone,
    project_id integer,
    status character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    duration integer,
    user_id integer,
    lock_version integer DEFAULT 0,
    auto_canceled_by_id integer,
    pipeline_schedule_id integer,
    source integer,
    config_source integer,
    protected boolean,
    failure_reason integer,
    iid integer,
    merge_request_id integer,
    source_sha bytea,
    target_sha bytea,
    external_pull_request_id bigint,
    ci_ref_id bigint
);

CREATE TABLE public.ci_pipelines_config (
    pipeline_id bigint NOT NULL,
    content text NOT NULL
);

CREATE SEQUENCE public.ci_pipelines_config_pipeline_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_pipelines_config_pipeline_id_seq OWNED BY public.ci_pipelines_config.pipeline_id;

CREATE SEQUENCE public.ci_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_pipelines_id_seq OWNED BY public.ci_pipelines.id;

CREATE TABLE public.ci_refs (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    ref_path text NOT NULL
);

CREATE SEQUENCE public.ci_refs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_refs_id_seq OWNED BY public.ci_refs.id;

CREATE TABLE public.ci_resource_groups (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id bigint NOT NULL,
    key character varying(255) NOT NULL
);

CREATE SEQUENCE public.ci_resource_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_resource_groups_id_seq OWNED BY public.ci_resource_groups.id;

CREATE TABLE public.ci_resources (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    resource_group_id bigint NOT NULL,
    build_id bigint
);

CREATE SEQUENCE public.ci_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_resources_id_seq OWNED BY public.ci_resources.id;

CREATE TABLE public.ci_runner_namespaces (
    id integer NOT NULL,
    runner_id integer,
    namespace_id integer
);

CREATE SEQUENCE public.ci_runner_namespaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_runner_namespaces_id_seq OWNED BY public.ci_runner_namespaces.id;

CREATE TABLE public.ci_runner_projects (
    id integer NOT NULL,
    runner_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer
);

CREATE SEQUENCE public.ci_runner_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_runner_projects_id_seq OWNED BY public.ci_runner_projects.id;

CREATE TABLE public.ci_runners (
    id integer NOT NULL,
    token character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description character varying,
    contacted_at timestamp without time zone,
    active boolean DEFAULT true NOT NULL,
    is_shared boolean DEFAULT false,
    name character varying,
    version character varying,
    revision character varying,
    platform character varying,
    architecture character varying,
    run_untagged boolean DEFAULT true NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    access_level integer DEFAULT 0 NOT NULL,
    ip_address character varying,
    maximum_timeout integer,
    runner_type smallint NOT NULL,
    token_encrypted character varying,
    public_projects_minutes_cost_factor double precision DEFAULT 0.0 NOT NULL,
    private_projects_minutes_cost_factor double precision DEFAULT 1.0 NOT NULL
);

CREATE SEQUENCE public.ci_runners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_runners_id_seq OWNED BY public.ci_runners.id;

CREATE TABLE public.ci_sources_pipelines (
    id integer NOT NULL,
    project_id integer,
    pipeline_id integer,
    source_project_id integer,
    source_job_id integer,
    source_pipeline_id integer
);

CREATE SEQUENCE public.ci_sources_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_sources_pipelines_id_seq OWNED BY public.ci_sources_pipelines.id;

CREATE TABLE public.ci_sources_projects (
    id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    source_project_id bigint NOT NULL
);

CREATE SEQUENCE public.ci_sources_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_sources_projects_id_seq OWNED BY public.ci_sources_projects.id;

CREATE TABLE public.ci_stages (
    id integer NOT NULL,
    project_id integer,
    pipeline_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying,
    status integer,
    lock_version integer DEFAULT 0,
    "position" integer
);

CREATE SEQUENCE public.ci_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_stages_id_seq OWNED BY public.ci_stages.id;

CREATE TABLE public.ci_subscriptions_projects (
    id bigint NOT NULL,
    downstream_project_id bigint NOT NULL,
    upstream_project_id bigint NOT NULL
);

CREATE SEQUENCE public.ci_subscriptions_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_subscriptions_projects_id_seq OWNED BY public.ci_subscriptions_projects.id;

CREATE TABLE public.ci_trigger_requests (
    id integer NOT NULL,
    trigger_id integer NOT NULL,
    variables text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    commit_id integer
);

CREATE SEQUENCE public.ci_trigger_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_trigger_requests_id_seq OWNED BY public.ci_trigger_requests.id;

CREATE TABLE public.ci_triggers (
    id integer NOT NULL,
    token character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer,
    owner_id integer NOT NULL,
    description character varying,
    ref character varying
);

CREATE SEQUENCE public.ci_triggers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_triggers_id_seq OWNED BY public.ci_triggers.id;

CREATE TABLE public.ci_variables (
    id integer NOT NULL,
    key character varying NOT NULL,
    value text,
    encrypted_value text,
    encrypted_value_salt character varying,
    encrypted_value_iv character varying,
    project_id integer NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    environment_scope character varying DEFAULT '*'::character varying NOT NULL,
    masked boolean DEFAULT false NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL
);

CREATE SEQUENCE public.ci_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ci_variables_id_seq OWNED BY public.ci_variables.id;

CREATE TABLE public.cluster_groups (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    group_id integer NOT NULL
);

CREATE SEQUENCE public.cluster_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.cluster_groups_id_seq OWNED BY public.cluster_groups.id;

CREATE TABLE public.cluster_platforms_kubernetes (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    api_url text,
    ca_cert text,
    namespace character varying,
    username character varying,
    encrypted_password text,
    encrypted_password_iv character varying,
    encrypted_token text,
    encrypted_token_iv character varying,
    authorization_type smallint
);

CREATE SEQUENCE public.cluster_platforms_kubernetes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.cluster_platforms_kubernetes_id_seq OWNED BY public.cluster_platforms_kubernetes.id;

CREATE TABLE public.cluster_projects (
    id integer NOT NULL,
    project_id integer NOT NULL,
    cluster_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.cluster_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.cluster_projects_id_seq OWNED BY public.cluster_projects.id;

CREATE TABLE public.cluster_providers_aws (
    id bigint NOT NULL,
    cluster_id bigint NOT NULL,
    created_by_user_id integer,
    num_nodes integer NOT NULL,
    status integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    key_name character varying(255) NOT NULL,
    role_arn character varying(2048) NOT NULL,
    region character varying(255) NOT NULL,
    vpc_id character varying(255) NOT NULL,
    subnet_ids character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    security_group_id character varying(255) NOT NULL,
    instance_type character varying(255) NOT NULL,
    access_key_id character varying(255),
    encrypted_secret_access_key_iv character varying(255),
    encrypted_secret_access_key text,
    session_token text,
    status_reason text
);

CREATE SEQUENCE public.cluster_providers_aws_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.cluster_providers_aws_id_seq OWNED BY public.cluster_providers_aws.id;

CREATE TABLE public.cluster_providers_gcp (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    status integer,
    num_nodes integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status_reason text,
    gcp_project_id character varying NOT NULL,
    zone character varying NOT NULL,
    machine_type character varying,
    operation_id character varying,
    endpoint character varying,
    encrypted_access_token text,
    encrypted_access_token_iv character varying,
    legacy_abac boolean DEFAULT false NOT NULL,
    cloud_run boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.cluster_providers_gcp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.cluster_providers_gcp_id_seq OWNED BY public.cluster_providers_gcp.id;

CREATE TABLE public.clusters (
    id integer NOT NULL,
    user_id integer,
    provider_type integer,
    platform_type integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    enabled boolean DEFAULT true,
    name character varying NOT NULL,
    environment_scope character varying DEFAULT '*'::character varying NOT NULL,
    cluster_type smallint DEFAULT 3 NOT NULL,
    domain character varying,
    managed boolean DEFAULT true NOT NULL,
    namespace_per_environment boolean DEFAULT true NOT NULL,
    management_project_id integer,
    cleanup_status smallint DEFAULT 1 NOT NULL,
    cleanup_status_reason text
);

CREATE TABLE public.clusters_applications_cert_managers (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    status integer NOT NULL,
    version character varying NOT NULL,
    email character varying NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status_reason text
);

CREATE SEQUENCE public.clusters_applications_cert_managers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_cert_managers_id_seq OWNED BY public.clusters_applications_cert_managers.id;

CREATE TABLE public.clusters_applications_crossplane (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    cluster_id bigint NOT NULL,
    status integer NOT NULL,
    version character varying(255) NOT NULL,
    stack character varying(255) NOT NULL,
    status_reason text
);

CREATE SEQUENCE public.clusters_applications_crossplane_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_crossplane_id_seq OWNED BY public.clusters_applications_crossplane.id;

CREATE TABLE public.clusters_applications_elastic_stacks (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    cluster_id bigint NOT NULL,
    status integer NOT NULL,
    version character varying(255) NOT NULL,
    status_reason text
);

CREATE SEQUENCE public.clusters_applications_elastic_stacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_elastic_stacks_id_seq OWNED BY public.clusters_applications_elastic_stacks.id;

CREATE TABLE public.clusters_applications_fluentd (
    id bigint NOT NULL,
    protocol smallint NOT NULL,
    status integer NOT NULL,
    port integer NOT NULL,
    cluster_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    version character varying(255) NOT NULL,
    host character varying(255) NOT NULL,
    status_reason text,
    waf_log_enabled boolean DEFAULT true NOT NULL,
    cilium_log_enabled boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.clusters_applications_fluentd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_fluentd_id_seq OWNED BY public.clusters_applications_fluentd.id;

CREATE TABLE public.clusters_applications_helm (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status integer NOT NULL,
    version character varying NOT NULL,
    status_reason text,
    encrypted_ca_key text,
    encrypted_ca_key_iv text,
    ca_cert text
);

CREATE SEQUENCE public.clusters_applications_helm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_helm_id_seq OWNED BY public.clusters_applications_helm.id;

CREATE TABLE public.clusters_applications_ingress (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status integer NOT NULL,
    ingress_type integer NOT NULL,
    version character varying NOT NULL,
    cluster_ip character varying,
    status_reason text,
    external_ip character varying,
    external_hostname character varying,
    modsecurity_enabled boolean,
    modsecurity_mode smallint DEFAULT 0 NOT NULL
);

CREATE SEQUENCE public.clusters_applications_ingress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_ingress_id_seq OWNED BY public.clusters_applications_ingress.id;

CREATE TABLE public.clusters_applications_jupyter (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    oauth_application_id integer,
    status integer NOT NULL,
    version character varying NOT NULL,
    hostname character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status_reason text
);

CREATE SEQUENCE public.clusters_applications_jupyter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_jupyter_id_seq OWNED BY public.clusters_applications_jupyter.id;

CREATE TABLE public.clusters_applications_knative (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status integer NOT NULL,
    version character varying NOT NULL,
    hostname character varying,
    status_reason text,
    external_ip character varying,
    external_hostname character varying
);

CREATE SEQUENCE public.clusters_applications_knative_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_knative_id_seq OWNED BY public.clusters_applications_knative.id;

CREATE TABLE public.clusters_applications_prometheus (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    status integer NOT NULL,
    version character varying NOT NULL,
    status_reason text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_update_started_at timestamp with time zone,
    encrypted_alert_manager_token character varying,
    encrypted_alert_manager_token_iv character varying,
    healthy boolean
);

CREATE SEQUENCE public.clusters_applications_prometheus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_prometheus_id_seq OWNED BY public.clusters_applications_prometheus.id;

CREATE TABLE public.clusters_applications_runners (
    id integer NOT NULL,
    cluster_id integer NOT NULL,
    runner_id integer,
    status integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    version character varying NOT NULL,
    status_reason text,
    privileged boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.clusters_applications_runners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_applications_runners_id_seq OWNED BY public.clusters_applications_runners.id;

CREATE SEQUENCE public.clusters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_id_seq OWNED BY public.clusters.id;

CREATE TABLE public.clusters_kubernetes_namespaces (
    id bigint NOT NULL,
    cluster_id integer NOT NULL,
    project_id integer,
    cluster_project_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_service_account_token text,
    encrypted_service_account_token_iv character varying,
    namespace character varying NOT NULL,
    service_account_name character varying,
    environment_id bigint
);

CREATE SEQUENCE public.clusters_kubernetes_namespaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.clusters_kubernetes_namespaces_id_seq OWNED BY public.clusters_kubernetes_namespaces.id;

CREATE TABLE public.commit_user_mentions (
    id bigint NOT NULL,
    note_id integer NOT NULL,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[],
    commit_id character varying NOT NULL
);

CREATE SEQUENCE public.commit_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.commit_user_mentions_id_seq OWNED BY public.commit_user_mentions.id;

CREATE TABLE public.container_expiration_policies (
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    next_run_at timestamp with time zone,
    name_regex character varying(255),
    cadence character varying(12) DEFAULT '1d'::character varying NOT NULL,
    older_than character varying(12) DEFAULT '90d'::character varying,
    keep_n integer DEFAULT 10,
    enabled boolean DEFAULT true NOT NULL,
    name_regex_keep text,
    CONSTRAINT container_expiration_policies_name_regex_keep CHECK ((char_length(name_regex_keep) <= 255))
);

CREATE TABLE public.container_repositories (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status smallint
);

CREATE SEQUENCE public.container_repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.container_repositories_id_seq OWNED BY public.container_repositories.id;

CREATE TABLE public.conversational_development_index_metrics (
    id integer NOT NULL,
    leader_issues double precision NOT NULL,
    instance_issues double precision NOT NULL,
    leader_notes double precision NOT NULL,
    instance_notes double precision NOT NULL,
    leader_milestones double precision NOT NULL,
    instance_milestones double precision NOT NULL,
    leader_boards double precision NOT NULL,
    instance_boards double precision NOT NULL,
    leader_merge_requests double precision NOT NULL,
    instance_merge_requests double precision NOT NULL,
    leader_ci_pipelines double precision NOT NULL,
    instance_ci_pipelines double precision NOT NULL,
    leader_environments double precision NOT NULL,
    instance_environments double precision NOT NULL,
    leader_deployments double precision NOT NULL,
    instance_deployments double precision NOT NULL,
    leader_projects_prometheus_active double precision NOT NULL,
    instance_projects_prometheus_active double precision NOT NULL,
    leader_service_desk_issues double precision NOT NULL,
    instance_service_desk_issues double precision NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    percentage_boards double precision DEFAULT 0.0 NOT NULL,
    percentage_ci_pipelines double precision DEFAULT 0.0 NOT NULL,
    percentage_deployments double precision DEFAULT 0.0 NOT NULL,
    percentage_environments double precision DEFAULT 0.0 NOT NULL,
    percentage_issues double precision DEFAULT 0.0 NOT NULL,
    percentage_merge_requests double precision DEFAULT 0.0 NOT NULL,
    percentage_milestones double precision DEFAULT 0.0 NOT NULL,
    percentage_notes double precision DEFAULT 0.0 NOT NULL,
    percentage_projects_prometheus_active double precision DEFAULT 0.0 NOT NULL,
    percentage_service_desk_issues double precision DEFAULT 0.0 NOT NULL
);

CREATE SEQUENCE public.conversational_development_index_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.conversational_development_index_metrics_id_seq OWNED BY public.conversational_development_index_metrics.id;

CREATE TABLE public.dependency_proxy_blobs (
    id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    size bigint,
    file_store integer,
    file_name character varying NOT NULL,
    file text NOT NULL
);

CREATE SEQUENCE public.dependency_proxy_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.dependency_proxy_blobs_id_seq OWNED BY public.dependency_proxy_blobs.id;

CREATE TABLE public.dependency_proxy_group_settings (
    id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    enabled boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.dependency_proxy_group_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.dependency_proxy_group_settings_id_seq OWNED BY public.dependency_proxy_group_settings.id;

CREATE TABLE public.deploy_keys_projects (
    id integer NOT NULL,
    deploy_key_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    can_push boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.deploy_keys_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.deploy_keys_projects_id_seq OWNED BY public.deploy_keys_projects.id;

CREATE TABLE public.deploy_tokens (
    id integer NOT NULL,
    revoked boolean DEFAULT false,
    read_repository boolean DEFAULT false NOT NULL,
    read_registry boolean DEFAULT false NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    name character varying NOT NULL,
    token character varying,
    username character varying,
    token_encrypted character varying(255),
    deploy_token_type smallint DEFAULT 2 NOT NULL,
    write_registry boolean DEFAULT false NOT NULL,
    read_package_registry boolean DEFAULT false NOT NULL,
    write_package_registry boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.deploy_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.deploy_tokens_id_seq OWNED BY public.deploy_tokens.id;

CREATE TABLE public.deployment_clusters (
    deployment_id integer NOT NULL,
    cluster_id integer NOT NULL,
    kubernetes_namespace character varying(255)
);

CREATE TABLE public.deployment_merge_requests (
    deployment_id integer NOT NULL,
    merge_request_id integer NOT NULL,
    environment_id integer
);

CREATE TABLE public.deployments (
    id integer NOT NULL,
    iid integer NOT NULL,
    project_id integer NOT NULL,
    environment_id integer NOT NULL,
    ref character varying NOT NULL,
    tag boolean NOT NULL,
    sha character varying NOT NULL,
    user_id integer,
    deployable_id integer,
    deployable_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    on_stop character varying,
    status smallint NOT NULL,
    finished_at timestamp with time zone,
    cluster_id integer
);

CREATE SEQUENCE public.deployments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.deployments_id_seq OWNED BY public.deployments.id;

CREATE TABLE public.description_versions (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    issue_id integer,
    merge_request_id integer,
    epic_id integer,
    description text,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE public.description_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.description_versions_id_seq OWNED BY public.description_versions.id;

CREATE TABLE public.design_management_designs (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    issue_id integer,
    filename character varying NOT NULL
);

CREATE SEQUENCE public.design_management_designs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.design_management_designs_id_seq OWNED BY public.design_management_designs.id;

CREATE TABLE public.design_management_designs_versions (
    id bigint NOT NULL,
    design_id bigint NOT NULL,
    version_id bigint NOT NULL,
    event smallint DEFAULT 0 NOT NULL,
    image_v432x230 character varying(255)
);

CREATE SEQUENCE public.design_management_designs_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.design_management_designs_versions_id_seq OWNED BY public.design_management_designs_versions.id;

CREATE TABLE public.design_management_versions (
    id bigint NOT NULL,
    sha bytea NOT NULL,
    issue_id bigint,
    created_at timestamp with time zone NOT NULL,
    author_id integer
);

CREATE SEQUENCE public.design_management_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.design_management_versions_id_seq OWNED BY public.design_management_versions.id;

CREATE TABLE public.design_user_mentions (
    id bigint NOT NULL,
    design_id integer NOT NULL,
    note_id integer NOT NULL,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.design_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.design_user_mentions_id_seq OWNED BY public.design_user_mentions.id;

CREATE TABLE public.diff_note_positions (
    id bigint NOT NULL,
    note_id bigint NOT NULL,
    old_line integer,
    new_line integer,
    diff_content_type smallint NOT NULL,
    diff_type smallint NOT NULL,
    line_code character varying(255) NOT NULL,
    base_sha bytea NOT NULL,
    start_sha bytea NOT NULL,
    head_sha bytea NOT NULL,
    old_path text NOT NULL,
    new_path text NOT NULL
);

CREATE SEQUENCE public.diff_note_positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.diff_note_positions_id_seq OWNED BY public.diff_note_positions.id;

CREATE TABLE public.draft_notes (
    id bigint NOT NULL,
    merge_request_id integer NOT NULL,
    author_id integer NOT NULL,
    resolve_discussion boolean DEFAULT false NOT NULL,
    discussion_id character varying,
    note text NOT NULL,
    "position" text,
    original_position text,
    change_position text,
    commit_id bytea
);

CREATE SEQUENCE public.draft_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.draft_notes_id_seq OWNED BY public.draft_notes.id;

CREATE TABLE public.elasticsearch_indexed_namespaces (
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    namespace_id integer
);

CREATE TABLE public.elasticsearch_indexed_projects (
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer
);

CREATE TABLE public.emails (
    id integer NOT NULL,
    user_id integer NOT NULL,
    email character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone
);

CREATE SEQUENCE public.emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.emails_id_seq OWNED BY public.emails.id;

CREATE TABLE public.environments (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    external_url character varying,
    environment_type character varying,
    state character varying DEFAULT 'available'::character varying NOT NULL,
    slug character varying NOT NULL,
    auto_stop_at timestamp with time zone
);

CREATE SEQUENCE public.environments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.environments_id_seq OWNED BY public.environments.id;

CREATE TABLE public.epic_issues (
    id integer NOT NULL,
    epic_id integer NOT NULL,
    issue_id integer NOT NULL,
    relative_position integer
);

CREATE SEQUENCE public.epic_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.epic_issues_id_seq OWNED BY public.epic_issues.id;

CREATE TABLE public.epic_metrics (
    id integer NOT NULL,
    epic_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.epic_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.epic_metrics_id_seq OWNED BY public.epic_metrics.id;

CREATE TABLE public.epic_user_mentions (
    id bigint NOT NULL,
    epic_id integer NOT NULL,
    note_id integer,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.epic_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.epic_user_mentions_id_seq OWNED BY public.epic_user_mentions.id;

CREATE TABLE public.epics (
    id integer NOT NULL,
    group_id integer NOT NULL,
    author_id integer NOT NULL,
    assignee_id integer,
    iid integer NOT NULL,
    cached_markdown_version integer,
    updated_by_id integer,
    last_edited_by_id integer,
    lock_version integer DEFAULT 0,
    start_date date,
    end_date date,
    last_edited_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying NOT NULL,
    title_html character varying NOT NULL,
    description text,
    description_html text,
    start_date_sourcing_milestone_id integer,
    due_date_sourcing_milestone_id integer,
    start_date_fixed date,
    due_date_fixed date,
    start_date_is_fixed boolean,
    due_date_is_fixed boolean,
    closed_by_id integer,
    closed_at timestamp without time zone,
    parent_id integer,
    relative_position integer,
    state_id smallint DEFAULT 1 NOT NULL,
    start_date_sourcing_epic_id integer,
    due_date_sourcing_epic_id integer,
    confidential boolean DEFAULT false NOT NULL,
    external_key character varying(255)
);

CREATE SEQUENCE public.epics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.epics_id_seq OWNED BY public.epics.id;

CREATE TABLE public.events (
    id integer NOT NULL,
    project_id integer,
    author_id integer NOT NULL,
    target_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    action smallint NOT NULL,
    target_type character varying,
    group_id bigint
);

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;

CREATE TABLE public.evidences (
    id bigint NOT NULL,
    release_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    summary_sha bytea,
    summary jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE SEQUENCE public.evidences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.evidences_id_seq OWNED BY public.evidences.id;

CREATE TABLE public.external_pull_requests (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id bigint NOT NULL,
    pull_request_iid integer NOT NULL,
    status smallint NOT NULL,
    source_branch character varying(255) NOT NULL,
    target_branch character varying(255) NOT NULL,
    source_repository character varying(255) NOT NULL,
    target_repository character varying(255) NOT NULL,
    source_sha bytea NOT NULL,
    target_sha bytea NOT NULL
);

CREATE SEQUENCE public.external_pull_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.external_pull_requests_id_seq OWNED BY public.external_pull_requests.id;

CREATE TABLE public.feature_gates (
    id integer NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.feature_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.feature_gates_id_seq OWNED BY public.feature_gates.id;

CREATE TABLE public.features (
    id integer NOT NULL,
    key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.features_id_seq OWNED BY public.features.id;

CREATE TABLE public.fork_network_members (
    id integer NOT NULL,
    fork_network_id integer NOT NULL,
    project_id integer NOT NULL,
    forked_from_project_id integer
);

CREATE SEQUENCE public.fork_network_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.fork_network_members_id_seq OWNED BY public.fork_network_members.id;

CREATE TABLE public.fork_networks (
    id integer NOT NULL,
    root_project_id integer,
    deleted_root_project_name character varying
);

CREATE SEQUENCE public.fork_networks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.fork_networks_id_seq OWNED BY public.fork_networks.id;

CREATE TABLE public.geo_cache_invalidation_events (
    id bigint NOT NULL,
    key character varying NOT NULL
);

CREATE SEQUENCE public.geo_cache_invalidation_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_cache_invalidation_events_id_seq OWNED BY public.geo_cache_invalidation_events.id;

CREATE TABLE public.geo_container_repository_updated_events (
    id bigint NOT NULL,
    container_repository_id integer NOT NULL
);

CREATE SEQUENCE public.geo_container_repository_updated_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_container_repository_updated_events_id_seq OWNED BY public.geo_container_repository_updated_events.id;

CREATE TABLE public.geo_event_log (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    repository_updated_event_id bigint,
    repository_deleted_event_id bigint,
    repository_renamed_event_id bigint,
    repositories_changed_event_id bigint,
    repository_created_event_id bigint,
    hashed_storage_migrated_event_id bigint,
    lfs_object_deleted_event_id bigint,
    hashed_storage_attachments_event_id bigint,
    upload_deleted_event_id bigint,
    job_artifact_deleted_event_id bigint,
    reset_checksum_event_id bigint,
    cache_invalidation_event_id bigint,
    container_repository_updated_event_id bigint,
    geo_event_id integer
);

CREATE SEQUENCE public.geo_event_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_event_log_id_seq OWNED BY public.geo_event_log.id;

CREATE TABLE public.geo_events (
    id bigint NOT NULL,
    replicable_name character varying(255) NOT NULL,
    event_name character varying(255) NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.geo_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_events_id_seq OWNED BY public.geo_events.id;

CREATE TABLE public.geo_hashed_storage_attachments_events (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    old_attachments_path text NOT NULL,
    new_attachments_path text NOT NULL
);

CREATE SEQUENCE public.geo_hashed_storage_attachments_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_hashed_storage_attachments_events_id_seq OWNED BY public.geo_hashed_storage_attachments_events.id;

CREATE TABLE public.geo_hashed_storage_migrated_events (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    repository_storage_name text NOT NULL,
    old_disk_path text NOT NULL,
    new_disk_path text NOT NULL,
    old_wiki_disk_path text NOT NULL,
    new_wiki_disk_path text NOT NULL,
    old_storage_version smallint,
    new_storage_version smallint NOT NULL,
    old_design_disk_path text,
    new_design_disk_path text
);

CREATE SEQUENCE public.geo_hashed_storage_migrated_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_hashed_storage_migrated_events_id_seq OWNED BY public.geo_hashed_storage_migrated_events.id;

CREATE TABLE public.geo_job_artifact_deleted_events (
    id bigint NOT NULL,
    job_artifact_id integer NOT NULL,
    file_path character varying NOT NULL
);

CREATE SEQUENCE public.geo_job_artifact_deleted_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_job_artifact_deleted_events_id_seq OWNED BY public.geo_job_artifact_deleted_events.id;

CREATE TABLE public.geo_lfs_object_deleted_events (
    id bigint NOT NULL,
    lfs_object_id integer NOT NULL,
    oid character varying NOT NULL,
    file_path character varying NOT NULL
);

CREATE SEQUENCE public.geo_lfs_object_deleted_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_lfs_object_deleted_events_id_seq OWNED BY public.geo_lfs_object_deleted_events.id;

CREATE TABLE public.geo_node_namespace_links (
    id integer NOT NULL,
    geo_node_id integer NOT NULL,
    namespace_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.geo_node_namespace_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_node_namespace_links_id_seq OWNED BY public.geo_node_namespace_links.id;

CREATE TABLE public.geo_node_statuses (
    id integer NOT NULL,
    geo_node_id integer NOT NULL,
    db_replication_lag_seconds integer,
    repositories_synced_count integer,
    repositories_failed_count integer,
    lfs_objects_count integer,
    lfs_objects_synced_count integer,
    lfs_objects_failed_count integer,
    attachments_count integer,
    attachments_synced_count integer,
    attachments_failed_count integer,
    last_event_id integer,
    last_event_date timestamp without time zone,
    cursor_last_event_id integer,
    cursor_last_event_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_successful_status_check_at timestamp without time zone,
    status_message character varying,
    replication_slots_count integer,
    replication_slots_used_count integer,
    replication_slots_max_retained_wal_bytes bigint,
    wikis_synced_count integer,
    wikis_failed_count integer,
    job_artifacts_count integer,
    job_artifacts_synced_count integer,
    job_artifacts_failed_count integer,
    version character varying,
    revision character varying,
    repositories_verified_count integer,
    repositories_verification_failed_count integer,
    wikis_verified_count integer,
    wikis_verification_failed_count integer,
    lfs_objects_synced_missing_on_primary_count integer,
    job_artifacts_synced_missing_on_primary_count integer,
    attachments_synced_missing_on_primary_count integer,
    repositories_checksummed_count integer,
    repositories_checksum_failed_count integer,
    repositories_checksum_mismatch_count integer,
    wikis_checksummed_count integer,
    wikis_checksum_failed_count integer,
    wikis_checksum_mismatch_count integer,
    storage_configuration_digest bytea,
    repositories_retrying_verification_count integer,
    wikis_retrying_verification_count integer,
    projects_count integer,
    container_repositories_count integer,
    container_repositories_synced_count integer,
    container_repositories_failed_count integer,
    container_repositories_registry_count integer,
    design_repositories_count integer,
    design_repositories_synced_count integer,
    design_repositories_failed_count integer,
    design_repositories_registry_count integer,
    status jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE SEQUENCE public.geo_node_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_node_statuses_id_seq OWNED BY public.geo_node_statuses.id;

CREATE TABLE public.geo_nodes (
    id integer NOT NULL,
    "primary" boolean DEFAULT false NOT NULL,
    oauth_application_id integer,
    enabled boolean DEFAULT true NOT NULL,
    access_key character varying,
    encrypted_secret_access_key character varying,
    encrypted_secret_access_key_iv character varying,
    clone_url_prefix character varying,
    files_max_capacity integer DEFAULT 10 NOT NULL,
    repos_max_capacity integer DEFAULT 25 NOT NULL,
    url character varying NOT NULL,
    selective_sync_type character varying,
    selective_sync_shards text,
    verification_max_capacity integer DEFAULT 100 NOT NULL,
    minimum_reverification_interval integer DEFAULT 7 NOT NULL,
    internal_url character varying,
    name character varying NOT NULL,
    container_repositories_max_capacity integer DEFAULT 10 NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    sync_object_storage boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.geo_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_nodes_id_seq OWNED BY public.geo_nodes.id;

CREATE TABLE public.geo_repositories_changed_events (
    id bigint NOT NULL,
    geo_node_id integer NOT NULL
);

CREATE SEQUENCE public.geo_repositories_changed_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_repositories_changed_events_id_seq OWNED BY public.geo_repositories_changed_events.id;

CREATE TABLE public.geo_repository_created_events (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    repository_storage_name text NOT NULL,
    repo_path text NOT NULL,
    wiki_path text,
    project_name text NOT NULL
);

CREATE SEQUENCE public.geo_repository_created_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_repository_created_events_id_seq OWNED BY public.geo_repository_created_events.id;

CREATE TABLE public.geo_repository_deleted_events (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    repository_storage_name text NOT NULL,
    deleted_path text NOT NULL,
    deleted_wiki_path text,
    deleted_project_name text NOT NULL
);

CREATE SEQUENCE public.geo_repository_deleted_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_repository_deleted_events_id_seq OWNED BY public.geo_repository_deleted_events.id;

CREATE TABLE public.geo_repository_renamed_events (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    repository_storage_name text NOT NULL,
    old_path_with_namespace text NOT NULL,
    new_path_with_namespace text NOT NULL,
    old_wiki_path_with_namespace text NOT NULL,
    new_wiki_path_with_namespace text NOT NULL,
    old_path text NOT NULL,
    new_path text NOT NULL
);

CREATE SEQUENCE public.geo_repository_renamed_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_repository_renamed_events_id_seq OWNED BY public.geo_repository_renamed_events.id;

CREATE TABLE public.geo_repository_updated_events (
    id bigint NOT NULL,
    branches_affected integer NOT NULL,
    tags_affected integer NOT NULL,
    project_id integer NOT NULL,
    source smallint NOT NULL,
    new_branch boolean DEFAULT false NOT NULL,
    remove_branch boolean DEFAULT false NOT NULL,
    ref text
);

CREATE SEQUENCE public.geo_repository_updated_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_repository_updated_events_id_seq OWNED BY public.geo_repository_updated_events.id;

CREATE TABLE public.geo_reset_checksum_events (
    id bigint NOT NULL,
    project_id integer NOT NULL
);

CREATE SEQUENCE public.geo_reset_checksum_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_reset_checksum_events_id_seq OWNED BY public.geo_reset_checksum_events.id;

CREATE TABLE public.geo_upload_deleted_events (
    id bigint NOT NULL,
    upload_id integer NOT NULL,
    file_path character varying NOT NULL,
    model_id integer NOT NULL,
    model_type character varying NOT NULL,
    uploader character varying NOT NULL
);

CREATE SEQUENCE public.geo_upload_deleted_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.geo_upload_deleted_events_id_seq OWNED BY public.geo_upload_deleted_events.id;

CREATE TABLE public.gitlab_subscription_histories (
    id bigint NOT NULL,
    gitlab_subscription_created_at timestamp with time zone,
    gitlab_subscription_updated_at timestamp with time zone,
    start_date date,
    end_date date,
    trial_ends_on date,
    namespace_id integer,
    hosted_plan_id integer,
    max_seats_used integer,
    seats integer,
    trial boolean,
    change_type smallint,
    gitlab_subscription_id bigint NOT NULL,
    created_at timestamp with time zone,
    trial_starts_on date,
    auto_renew boolean
);

CREATE SEQUENCE public.gitlab_subscription_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.gitlab_subscription_histories_id_seq OWNED BY public.gitlab_subscription_histories.id;

CREATE TABLE public.gitlab_subscriptions (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    start_date date,
    end_date date,
    trial_ends_on date,
    namespace_id integer,
    hosted_plan_id integer,
    max_seats_used integer DEFAULT 0,
    seats integer DEFAULT 0,
    trial boolean DEFAULT false,
    trial_starts_on date,
    auto_renew boolean
);

CREATE SEQUENCE public.gitlab_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.gitlab_subscriptions_id_seq OWNED BY public.gitlab_subscriptions.id;

CREATE TABLE public.gpg_key_subkeys (
    id integer NOT NULL,
    gpg_key_id integer NOT NULL,
    keyid bytea,
    fingerprint bytea
);

CREATE SEQUENCE public.gpg_key_subkeys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.gpg_key_subkeys_id_seq OWNED BY public.gpg_key_subkeys.id;

CREATE TABLE public.gpg_keys (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer,
    primary_keyid bytea,
    fingerprint bytea,
    key text
);

CREATE SEQUENCE public.gpg_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.gpg_keys_id_seq OWNED BY public.gpg_keys.id;

CREATE TABLE public.gpg_signatures (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer,
    gpg_key_id integer,
    commit_sha bytea,
    gpg_key_primary_keyid bytea,
    gpg_key_user_name text,
    gpg_key_user_email text,
    verification_status smallint DEFAULT 0 NOT NULL,
    gpg_key_subkey_id integer
);

CREATE SEQUENCE public.gpg_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.gpg_signatures_id_seq OWNED BY public.gpg_signatures.id;

CREATE TABLE public.grafana_integrations (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_token character varying(255) NOT NULL,
    encrypted_token_iv character varying(255) NOT NULL,
    grafana_url character varying(1024) NOT NULL,
    enabled boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.grafana_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.grafana_integrations_id_seq OWNED BY public.grafana_integrations.id;

CREATE TABLE public.group_custom_attributes (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    group_id integer NOT NULL,
    key character varying NOT NULL,
    value character varying NOT NULL
);

CREATE SEQUENCE public.group_custom_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.group_custom_attributes_id_seq OWNED BY public.group_custom_attributes.id;

CREATE TABLE public.group_deletion_schedules (
    group_id bigint NOT NULL,
    user_id bigint NOT NULL,
    marked_for_deletion_on date NOT NULL
);

CREATE TABLE public.group_deploy_keys (
    id bigint NOT NULL,
    user_id bigint,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone,
    key text NOT NULL,
    title text,
    fingerprint text NOT NULL,
    fingerprint_sha256 bytea,
    CONSTRAINT check_cc0365908d CHECK ((char_length(title) <= 255)),
    CONSTRAINT check_e4526dcf91 CHECK ((char_length(fingerprint) <= 255)),
    CONSTRAINT check_f58fa0a0f7 CHECK ((char_length(key) <= 4096))
);

CREATE SEQUENCE public.group_deploy_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.group_deploy_keys_id_seq OWNED BY public.group_deploy_keys.id;

CREATE TABLE public.group_deploy_tokens (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    group_id bigint NOT NULL,
    deploy_token_id bigint NOT NULL
);

CREATE SEQUENCE public.group_deploy_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.group_deploy_tokens_id_seq OWNED BY public.group_deploy_tokens.id;

CREATE TABLE public.group_group_links (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    shared_group_id bigint NOT NULL,
    shared_with_group_id bigint NOT NULL,
    expires_at date,
    group_access smallint DEFAULT 30 NOT NULL
);

CREATE SEQUENCE public.group_group_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.group_group_links_id_seq OWNED BY public.group_group_links.id;

CREATE TABLE public.group_import_states (
    group_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    jid text,
    last_error text,
    CONSTRAINT check_87b58f6b30 CHECK ((char_length(last_error) <= 255)),
    CONSTRAINT check_96558fff96 CHECK ((char_length(jid) <= 100))
);

CREATE SEQUENCE public.group_import_states_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.group_import_states_group_id_seq OWNED BY public.group_import_states.group_id;

CREATE TABLE public.group_wiki_repositories (
    shard_id bigint NOT NULL,
    group_id bigint NOT NULL,
    disk_path text NOT NULL,
    CONSTRAINT check_07f1c81806 CHECK ((char_length(disk_path) <= 80))
);

CREATE TABLE public.historical_data (
    id integer NOT NULL,
    date date NOT NULL,
    active_user_count integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.historical_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.historical_data_id_seq OWNED BY public.historical_data.id;

CREATE TABLE public.identities (
    id integer NOT NULL,
    extern_uid character varying,
    provider character varying,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    secondary_extern_uid character varying,
    saml_provider_id integer
);

CREATE SEQUENCE public.identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.identities_id_seq OWNED BY public.identities.id;

CREATE TABLE public.import_export_uploads (
    id integer NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer,
    import_file text,
    export_file text,
    group_id bigint
);

CREATE SEQUENCE public.import_export_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.import_export_uploads_id_seq OWNED BY public.import_export_uploads.id;

CREATE TABLE public.import_failures (
    id bigint NOT NULL,
    relation_index integer,
    project_id bigint,
    created_at timestamp with time zone NOT NULL,
    relation_key character varying(64),
    exception_class character varying(128),
    correlation_id_value character varying(128),
    exception_message character varying(255),
    retry_count integer,
    group_id integer,
    source character varying(128)
);

CREATE SEQUENCE public.import_failures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.import_failures_id_seq OWNED BY public.import_failures.id;

CREATE TABLE public.index_statuses (
    id integer NOT NULL,
    project_id integer NOT NULL,
    indexed_at timestamp without time zone,
    note text,
    last_commit character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_wiki_commit bytea,
    wiki_indexed_at timestamp with time zone
);

CREATE SEQUENCE public.index_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.index_statuses_id_seq OWNED BY public.index_statuses.id;

CREATE TABLE public.insights (
    id integer NOT NULL,
    namespace_id integer NOT NULL,
    project_id integer NOT NULL
);

CREATE SEQUENCE public.insights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.insights_id_seq OWNED BY public.insights.id;

CREATE TABLE public.internal_ids (
    id bigint NOT NULL,
    project_id integer,
    usage integer NOT NULL,
    last_value integer NOT NULL,
    namespace_id integer
);

CREATE SEQUENCE public.internal_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.internal_ids_id_seq OWNED BY public.internal_ids.id;

CREATE TABLE public.ip_restrictions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    range character varying NOT NULL
);

CREATE SEQUENCE public.ip_restrictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ip_restrictions_id_seq OWNED BY public.ip_restrictions.id;

CREATE TABLE public.issue_assignees (
    user_id integer NOT NULL,
    issue_id integer NOT NULL
);

CREATE TABLE public.issue_links (
    id integer NOT NULL,
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    link_type smallint DEFAULT 0 NOT NULL
);

CREATE SEQUENCE public.issue_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.issue_links_id_seq OWNED BY public.issue_links.id;

CREATE TABLE public.issue_metrics (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    first_mentioned_in_commit_at timestamp without time zone,
    first_associated_with_milestone_at timestamp without time zone,
    first_added_to_board_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.issue_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.issue_metrics_id_seq OWNED BY public.issue_metrics.id;

CREATE TABLE public.issue_tracker_data (
    id bigint NOT NULL,
    service_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_project_url character varying,
    encrypted_project_url_iv character varying,
    encrypted_issues_url character varying,
    encrypted_issues_url_iv character varying,
    encrypted_new_issue_url character varying,
    encrypted_new_issue_url_iv character varying
);

CREATE SEQUENCE public.issue_tracker_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.issue_tracker_data_id_seq OWNED BY public.issue_tracker_data.id;

CREATE TABLE public.issue_user_mentions (
    id bigint NOT NULL,
    issue_id integer NOT NULL,
    note_id integer,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.issue_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.issue_user_mentions_id_seq OWNED BY public.issue_user_mentions.id;

CREATE TABLE public.issues (
    id integer NOT NULL,
    title character varying,
    author_id integer,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    milestone_id integer,
    iid integer,
    updated_by_id integer,
    weight integer,
    confidential boolean DEFAULT false NOT NULL,
    due_date date,
    moved_to_id integer,
    lock_version integer DEFAULT 0,
    title_html text,
    description_html text,
    time_estimate integer,
    relative_position integer,
    service_desk_reply_to character varying,
    cached_markdown_version integer,
    last_edited_at timestamp without time zone,
    last_edited_by_id integer,
    discussion_locked boolean,
    closed_at timestamp with time zone,
    closed_by_id integer,
    state_id smallint DEFAULT 1 NOT NULL,
    duplicated_to_id integer,
    promoted_to_epic_id integer,
    health_status smallint,
    external_key character varying(255),
    sprint_id bigint
);

CREATE SEQUENCE public.issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;

CREATE TABLE public.issues_prometheus_alert_events (
    issue_id bigint NOT NULL,
    prometheus_alert_event_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE public.issues_self_managed_prometheus_alert_events (
    issue_id bigint NOT NULL,
    self_managed_prometheus_alert_event_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE public.jira_connect_installations (
    id bigint NOT NULL,
    client_key character varying,
    encrypted_shared_secret character varying,
    encrypted_shared_secret_iv character varying,
    base_url character varying
);

CREATE SEQUENCE public.jira_connect_installations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.jira_connect_installations_id_seq OWNED BY public.jira_connect_installations.id;

CREATE TABLE public.jira_connect_subscriptions (
    id bigint NOT NULL,
    jira_connect_installation_id bigint NOT NULL,
    namespace_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.jira_connect_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.jira_connect_subscriptions_id_seq OWNED BY public.jira_connect_subscriptions.id;

CREATE TABLE public.jira_imports (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint,
    label_id bigint,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    jira_project_xid bigint NOT NULL,
    total_issue_count integer DEFAULT 0 NOT NULL,
    imported_issues_count integer DEFAULT 0 NOT NULL,
    failed_to_import_count integer DEFAULT 0 NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    jid character varying(255),
    jira_project_key character varying(255) NOT NULL,
    jira_project_name character varying(255) NOT NULL,
    scheduled_at timestamp with time zone,
    error_message text,
    CONSTRAINT check_9ed451c5b1 CHECK ((char_length(error_message) <= 1000))
);

CREATE SEQUENCE public.jira_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.jira_imports_id_seq OWNED BY public.jira_imports.id;

CREATE TABLE public.jira_tracker_data (
    id bigint NOT NULL,
    service_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_url character varying,
    encrypted_url_iv character varying,
    encrypted_api_url character varying,
    encrypted_api_url_iv character varying,
    encrypted_username character varying,
    encrypted_username_iv character varying,
    encrypted_password character varying,
    encrypted_password_iv character varying,
    jira_issue_transition_id character varying
);

CREATE SEQUENCE public.jira_tracker_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.jira_tracker_data_id_seq OWNED BY public.jira_tracker_data.id;

CREATE TABLE public.keys (
    id integer NOT NULL,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    key text,
    title character varying,
    type character varying,
    fingerprint character varying,
    public boolean DEFAULT false NOT NULL,
    last_used_at timestamp without time zone,
    fingerprint_sha256 bytea,
    expires_at timestamp with time zone
);

CREATE SEQUENCE public.keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.keys_id_seq OWNED BY public.keys.id;

CREATE TABLE public.label_links (
    id integer NOT NULL,
    label_id integer,
    target_id integer,
    target_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.label_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.label_links_id_seq OWNED BY public.label_links.id;

CREATE TABLE public.label_priorities (
    id integer NOT NULL,
    project_id integer NOT NULL,
    label_id integer NOT NULL,
    priority integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.label_priorities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.label_priorities_id_seq OWNED BY public.label_priorities.id;

CREATE TABLE public.labels (
    id integer NOT NULL,
    title character varying,
    color character varying,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    template boolean DEFAULT false,
    description character varying,
    description_html text,
    type character varying,
    group_id integer,
    cached_markdown_version integer
);

CREATE SEQUENCE public.labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;

CREATE TABLE public.ldap_group_links (
    id integer NOT NULL,
    cn character varying,
    group_access integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    provider character varying,
    filter character varying
);

CREATE SEQUENCE public.ldap_group_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ldap_group_links_id_seq OWNED BY public.ldap_group_links.id;

CREATE TABLE public.lfs_file_locks (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    path character varying(511)
);

CREATE SEQUENCE public.lfs_file_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.lfs_file_locks_id_seq OWNED BY public.lfs_file_locks.id;

CREATE TABLE public.lfs_objects (
    id integer NOT NULL,
    oid character varying NOT NULL,
    size bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    file character varying,
    file_store integer DEFAULT 1
);

CREATE SEQUENCE public.lfs_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.lfs_objects_id_seq OWNED BY public.lfs_objects.id;

CREATE TABLE public.lfs_objects_projects (
    id integer NOT NULL,
    lfs_object_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    repository_type smallint
);

CREATE SEQUENCE public.lfs_objects_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.lfs_objects_projects_id_seq OWNED BY public.lfs_objects_projects.id;

CREATE TABLE public.licenses (
    id integer NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.licenses_id_seq OWNED BY public.licenses.id;

CREATE TABLE public.list_user_preferences (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    list_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    collapsed boolean
);

CREATE SEQUENCE public.list_user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.list_user_preferences_id_seq OWNED BY public.list_user_preferences.id;

CREATE TABLE public.lists (
    id integer NOT NULL,
    board_id integer NOT NULL,
    label_id integer,
    list_type integer DEFAULT 1 NOT NULL,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    milestone_id integer,
    max_issue_count integer DEFAULT 0 NOT NULL,
    max_issue_weight integer DEFAULT 0 NOT NULL,
    limit_metric character varying(20)
);

CREATE SEQUENCE public.lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.lists_id_seq OWNED BY public.lists.id;

CREATE TABLE public.members (
    id integer NOT NULL,
    access_level integer NOT NULL,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    user_id integer,
    notification_level integer NOT NULL,
    type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by_id integer,
    invite_email character varying,
    invite_token character varying,
    invite_accepted_at timestamp without time zone,
    requested_at timestamp without time zone,
    expires_at date,
    ldap boolean DEFAULT false NOT NULL,
    override boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.members_id_seq OWNED BY public.members.id;

CREATE TABLE public.merge_request_assignees (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    merge_request_id integer NOT NULL,
    created_at timestamp with time zone
);

CREATE SEQUENCE public.merge_request_assignees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_request_assignees_id_seq OWNED BY public.merge_request_assignees.id;

CREATE TABLE public.merge_request_blocks (
    id bigint NOT NULL,
    blocking_merge_request_id integer NOT NULL,
    blocked_merge_request_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.merge_request_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_request_blocks_id_seq OWNED BY public.merge_request_blocks.id;

CREATE TABLE public.merge_request_context_commit_diff_files (
    sha bytea NOT NULL,
    relative_order integer NOT NULL,
    new_file boolean NOT NULL,
    renamed_file boolean NOT NULL,
    deleted_file boolean NOT NULL,
    too_large boolean NOT NULL,
    a_mode character varying(255) NOT NULL,
    b_mode character varying(255) NOT NULL,
    new_path text NOT NULL,
    old_path text NOT NULL,
    diff text,
    "binary" boolean,
    merge_request_context_commit_id bigint
);

CREATE TABLE public.merge_request_context_commits (
    id bigint NOT NULL,
    authored_date timestamp with time zone,
    committed_date timestamp with time zone,
    relative_order integer NOT NULL,
    sha bytea NOT NULL,
    author_name text,
    author_email text,
    committer_name text,
    committer_email text,
    message text,
    merge_request_id bigint
);

CREATE SEQUENCE public.merge_request_context_commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_request_context_commits_id_seq OWNED BY public.merge_request_context_commits.id;

CREATE TABLE public.merge_request_diff_commits (
    authored_date timestamp without time zone,
    committed_date timestamp without time zone,
    merge_request_diff_id integer NOT NULL,
    relative_order integer NOT NULL,
    sha bytea NOT NULL,
    author_name text,
    author_email text,
    committer_name text,
    committer_email text,
    message text
);

CREATE TABLE public.merge_request_diff_files (
    merge_request_diff_id integer NOT NULL,
    relative_order integer NOT NULL,
    new_file boolean NOT NULL,
    renamed_file boolean NOT NULL,
    deleted_file boolean NOT NULL,
    too_large boolean NOT NULL,
    a_mode character varying NOT NULL,
    b_mode character varying NOT NULL,
    new_path text NOT NULL,
    old_path text NOT NULL,
    diff text,
    "binary" boolean,
    external_diff_offset integer,
    external_diff_size integer
);

CREATE TABLE public.merge_request_diffs (
    id integer NOT NULL,
    state character varying,
    merge_request_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    base_commit_sha character varying,
    real_size character varying,
    head_commit_sha character varying,
    start_commit_sha character varying,
    commits_count integer,
    external_diff character varying,
    external_diff_store integer,
    stored_externally boolean
);

CREATE SEQUENCE public.merge_request_diffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_request_diffs_id_seq OWNED BY public.merge_request_diffs.id;

CREATE TABLE public.merge_request_metrics (
    id integer NOT NULL,
    merge_request_id integer NOT NULL,
    latest_build_started_at timestamp without time zone,
    latest_build_finished_at timestamp without time zone,
    first_deployed_to_production_at timestamp without time zone,
    merged_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    pipeline_id integer,
    merged_by_id integer,
    latest_closed_by_id integer,
    latest_closed_at timestamp with time zone,
    first_comment_at timestamp with time zone,
    first_commit_at timestamp with time zone,
    last_commit_at timestamp with time zone,
    diff_size integer,
    modified_paths_size integer,
    commits_count integer,
    first_approved_at timestamp with time zone,
    first_reassigned_at timestamp with time zone,
    added_lines integer,
    removed_lines integer
);

CREATE SEQUENCE public.merge_request_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_request_metrics_id_seq OWNED BY public.merge_request_metrics.id;

CREATE TABLE public.merge_request_user_mentions (
    id bigint NOT NULL,
    merge_request_id integer NOT NULL,
    note_id integer,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.merge_request_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_request_user_mentions_id_seq OWNED BY public.merge_request_user_mentions.id;

CREATE TABLE public.merge_requests (
    id integer NOT NULL,
    target_branch character varying NOT NULL,
    source_branch character varying NOT NULL,
    source_project_id integer,
    author_id integer,
    assignee_id integer,
    title character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    milestone_id integer,
    merge_status character varying DEFAULT 'unchecked'::character varying NOT NULL,
    target_project_id integer NOT NULL,
    iid integer,
    description text,
    updated_by_id integer,
    merge_error text,
    merge_params text,
    merge_when_pipeline_succeeds boolean DEFAULT false NOT NULL,
    merge_user_id integer,
    merge_commit_sha character varying,
    approvals_before_merge integer,
    rebase_commit_sha character varying,
    in_progress_merge_commit_sha character varying,
    lock_version integer DEFAULT 0,
    title_html text,
    description_html text,
    time_estimate integer,
    squash boolean DEFAULT false NOT NULL,
    cached_markdown_version integer,
    last_edited_at timestamp without time zone,
    last_edited_by_id integer,
    head_pipeline_id integer,
    merge_jid character varying,
    discussion_locked boolean,
    latest_merge_request_diff_id integer,
    allow_maintainer_to_push boolean,
    state_id smallint DEFAULT 1 NOT NULL,
    rebase_jid character varying,
    squash_commit_sha bytea,
    sprint_id bigint
);

CREATE TABLE public.merge_requests_closing_issues (
    id integer NOT NULL,
    merge_request_id integer NOT NULL,
    issue_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.merge_requests_closing_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_requests_closing_issues_id_seq OWNED BY public.merge_requests_closing_issues.id;

CREATE SEQUENCE public.merge_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_requests_id_seq OWNED BY public.merge_requests.id;

CREATE TABLE public.merge_trains (
    id bigint NOT NULL,
    merge_request_id integer NOT NULL,
    user_id integer NOT NULL,
    pipeline_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    target_project_id integer NOT NULL,
    target_branch text NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    merged_at timestamp with time zone,
    duration integer
);

CREATE SEQUENCE public.merge_trains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.merge_trains_id_seq OWNED BY public.merge_trains.id;

CREATE TABLE public.metrics_dashboard_annotations (
    id bigint NOT NULL,
    starting_at timestamp with time zone NOT NULL,
    ending_at timestamp with time zone,
    environment_id bigint,
    cluster_id bigint,
    dashboard_path character varying(255) NOT NULL,
    panel_xid character varying(255),
    description text NOT NULL
);

CREATE SEQUENCE public.metrics_dashboard_annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.metrics_dashboard_annotations_id_seq OWNED BY public.metrics_dashboard_annotations.id;

CREATE TABLE public.metrics_users_starred_dashboards (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    dashboard_path text NOT NULL,
    CONSTRAINT check_79a84a0f57 CHECK ((char_length(dashboard_path) <= 255))
);

CREATE SEQUENCE public.metrics_users_starred_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.metrics_users_starred_dashboards_id_seq OWNED BY public.metrics_users_starred_dashboards.id;

CREATE TABLE public.milestone_releases (
    milestone_id bigint NOT NULL,
    release_id bigint NOT NULL
);

CREATE TABLE public.milestones (
    id integer NOT NULL,
    title character varying NOT NULL,
    project_id integer,
    description text,
    due_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    state character varying,
    iid integer,
    title_html text,
    description_html text,
    start_date date,
    cached_markdown_version integer,
    group_id integer
);

CREATE SEQUENCE public.milestones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.milestones_id_seq OWNED BY public.milestones.id;

CREATE TABLE public.namespace_aggregation_schedules (
    namespace_id integer NOT NULL
);

CREATE TABLE public.namespace_root_storage_statistics (
    namespace_id integer NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    repository_size bigint DEFAULT 0 NOT NULL,
    lfs_objects_size bigint DEFAULT 0 NOT NULL,
    wiki_size bigint DEFAULT 0 NOT NULL,
    build_artifacts_size bigint DEFAULT 0 NOT NULL,
    storage_size bigint DEFAULT 0 NOT NULL,
    packages_size bigint DEFAULT 0 NOT NULL
);

CREATE TABLE public.namespace_statistics (
    id integer NOT NULL,
    namespace_id integer NOT NULL,
    shared_runners_seconds integer DEFAULT 0 NOT NULL,
    shared_runners_seconds_last_reset timestamp without time zone
);

CREATE SEQUENCE public.namespace_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.namespace_statistics_id_seq OWNED BY public.namespace_statistics.id;

CREATE TABLE public.namespaces (
    id integer NOT NULL,
    name character varying NOT NULL,
    path character varying NOT NULL,
    owner_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying,
    description character varying DEFAULT ''::character varying NOT NULL,
    avatar character varying,
    membership_lock boolean DEFAULT false,
    share_with_group_lock boolean DEFAULT false,
    visibility_level integer DEFAULT 20 NOT NULL,
    request_access_enabled boolean DEFAULT true NOT NULL,
    ldap_sync_status character varying DEFAULT 'ready'::character varying NOT NULL,
    ldap_sync_error character varying,
    ldap_sync_last_update_at timestamp without time zone,
    ldap_sync_last_successful_update_at timestamp without time zone,
    ldap_sync_last_sync_at timestamp without time zone,
    description_html text,
    lfs_enabled boolean,
    parent_id integer,
    shared_runners_minutes_limit integer,
    repository_size_limit bigint,
    require_two_factor_authentication boolean DEFAULT false NOT NULL,
    two_factor_grace_period integer DEFAULT 48 NOT NULL,
    cached_markdown_version integer,
    project_creation_level integer,
    runners_token character varying,
    file_template_project_id integer,
    saml_discovery_token character varying,
    runners_token_encrypted character varying,
    custom_project_templates_group_id integer,
    auto_devops_enabled boolean,
    extra_shared_runners_minutes_limit integer,
    last_ci_minutes_notification_at timestamp with time zone,
    last_ci_minutes_usage_notification_level integer,
    subgroup_creation_level integer DEFAULT 1,
    emails_disabled boolean,
    max_pages_size integer,
    max_artifacts_size integer,
    mentions_disabled boolean,
    default_branch_protection smallint,
    unlock_membership_to_ldap boolean,
    max_personal_access_token_lifetime integer,
    push_rule_id bigint
);

CREATE SEQUENCE public.namespaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.namespaces_id_seq OWNED BY public.namespaces.id;

CREATE TABLE public.note_diff_files (
    id integer NOT NULL,
    diff_note_id integer NOT NULL,
    diff text NOT NULL,
    new_file boolean NOT NULL,
    renamed_file boolean NOT NULL,
    deleted_file boolean NOT NULL,
    a_mode character varying NOT NULL,
    b_mode character varying NOT NULL,
    new_path text NOT NULL,
    old_path text NOT NULL
);

CREATE SEQUENCE public.note_diff_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.note_diff_files_id_seq OWNED BY public.note_diff_files.id;

CREATE TABLE public.notes (
    id integer NOT NULL,
    note text,
    noteable_type character varying,
    author_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer,
    attachment character varying,
    line_code character varying,
    commit_id character varying,
    noteable_id integer,
    system boolean DEFAULT false NOT NULL,
    st_diff text,
    updated_by_id integer,
    type character varying,
    "position" text,
    original_position text,
    resolved_at timestamp without time zone,
    resolved_by_id integer,
    discussion_id character varying,
    note_html text,
    cached_markdown_version integer,
    change_position text,
    resolved_by_push boolean,
    review_id bigint,
    confidential boolean
);

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;

CREATE TABLE public.notification_settings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    source_id integer,
    source_type character varying,
    level integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    new_note boolean,
    new_issue boolean,
    reopen_issue boolean,
    close_issue boolean,
    reassign_issue boolean,
    new_merge_request boolean,
    reopen_merge_request boolean,
    close_merge_request boolean,
    reassign_merge_request boolean,
    merge_merge_request boolean,
    failed_pipeline boolean,
    success_pipeline boolean,
    push_to_merge_request boolean,
    issue_due boolean,
    new_epic boolean,
    notification_email character varying,
    fixed_pipeline boolean,
    new_release boolean
);

CREATE SEQUENCE public.notification_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.notification_settings_id_seq OWNED BY public.notification_settings.id;

CREATE TABLE public.oauth_access_grants (
    id integer NOT NULL,
    resource_owner_id integer NOT NULL,
    application_id integer NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying
);

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;

CREATE TABLE public.oauth_access_tokens (
    id integer NOT NULL,
    resource_owner_id integer,
    application_id integer,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying
);

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;

CREATE TABLE public.oauth_applications (
    id integer NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    owner_id integer,
    owner_type character varying,
    trusted boolean DEFAULT false NOT NULL,
    confidential boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;

CREATE TABLE public.oauth_openid_requests (
    id integer NOT NULL,
    access_grant_id integer NOT NULL,
    nonce character varying NOT NULL
);

CREATE SEQUENCE public.oauth_openid_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.oauth_openid_requests_id_seq OWNED BY public.oauth_openid_requests.id;

CREATE TABLE public.open_project_tracker_data (
    id bigint NOT NULL,
    service_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_url character varying(255),
    encrypted_url_iv character varying(255),
    encrypted_api_url character varying(255),
    encrypted_api_url_iv character varying(255),
    encrypted_token character varying(255),
    encrypted_token_iv character varying(255),
    closed_status_id character varying(5),
    project_identifier_code character varying(100)
);

CREATE SEQUENCE public.open_project_tracker_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.open_project_tracker_data_id_seq OWNED BY public.open_project_tracker_data.id;

CREATE TABLE public.operations_feature_flag_scopes (
    id bigint NOT NULL,
    feature_flag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    active boolean NOT NULL,
    environment_scope character varying DEFAULT '*'::character varying NOT NULL,
    strategies jsonb DEFAULT '[{"name": "default", "parameters": {}}]'::jsonb NOT NULL
);

CREATE SEQUENCE public.operations_feature_flag_scopes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_feature_flag_scopes_id_seq OWNED BY public.operations_feature_flag_scopes.id;

CREATE TABLE public.operations_feature_flags (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying NOT NULL,
    description text,
    iid integer NOT NULL,
    version smallint DEFAULT 1 NOT NULL
);

CREATE TABLE public.operations_feature_flags_clients (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    token_encrypted character varying
);

CREATE SEQUENCE public.operations_feature_flags_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_feature_flags_clients_id_seq OWNED BY public.operations_feature_flags_clients.id;

CREATE SEQUENCE public.operations_feature_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_feature_flags_id_seq OWNED BY public.operations_feature_flags.id;

CREATE TABLE public.operations_feature_flags_issues (
    id bigint NOT NULL,
    feature_flag_id bigint NOT NULL,
    issue_id bigint NOT NULL
);

CREATE SEQUENCE public.operations_feature_flags_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_feature_flags_issues_id_seq OWNED BY public.operations_feature_flags_issues.id;

CREATE TABLE public.operations_scopes (
    id bigint NOT NULL,
    strategy_id bigint NOT NULL,
    environment_scope character varying(255) NOT NULL
);

CREATE SEQUENCE public.operations_scopes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_scopes_id_seq OWNED BY public.operations_scopes.id;

CREATE TABLE public.operations_strategies (
    id bigint NOT NULL,
    feature_flag_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    parameters jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE SEQUENCE public.operations_strategies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_strategies_id_seq OWNED BY public.operations_strategies.id;

CREATE TABLE public.operations_strategies_user_lists (
    id bigint NOT NULL,
    strategy_id bigint NOT NULL,
    user_list_id bigint NOT NULL
);

CREATE SEQUENCE public.operations_strategies_user_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_strategies_user_lists_id_seq OWNED BY public.operations_strategies_user_lists.id;

CREATE TABLE public.operations_user_lists (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    iid integer NOT NULL,
    name character varying(255) NOT NULL,
    user_xids text DEFAULT ''::text NOT NULL
);

CREATE SEQUENCE public.operations_user_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.operations_user_lists_id_seq OWNED BY public.operations_user_lists.id;

CREATE TABLE public.packages_build_infos (
    id bigint NOT NULL,
    package_id integer NOT NULL,
    pipeline_id integer
);

CREATE SEQUENCE public.packages_build_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_build_infos_id_seq OWNED BY public.packages_build_infos.id;

CREATE TABLE public.packages_composer_metadata (
    package_id bigint NOT NULL,
    target_sha bytea NOT NULL,
    composer_json jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE public.packages_conan_file_metadata (
    id bigint NOT NULL,
    package_file_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    recipe_revision character varying(255) DEFAULT '0'::character varying NOT NULL,
    package_revision character varying(255),
    conan_package_reference character varying(255),
    conan_file_type smallint NOT NULL
);

CREATE SEQUENCE public.packages_conan_file_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_conan_file_metadata_id_seq OWNED BY public.packages_conan_file_metadata.id;

CREATE TABLE public.packages_conan_metadata (
    id bigint NOT NULL,
    package_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    package_username character varying(255) NOT NULL,
    package_channel character varying(255) NOT NULL
);

CREATE SEQUENCE public.packages_conan_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_conan_metadata_id_seq OWNED BY public.packages_conan_metadata.id;

CREATE TABLE public.packages_dependencies (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    version_pattern character varying(255) NOT NULL
);

CREATE SEQUENCE public.packages_dependencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_dependencies_id_seq OWNED BY public.packages_dependencies.id;

CREATE TABLE public.packages_dependency_links (
    id bigint NOT NULL,
    package_id bigint NOT NULL,
    dependency_id bigint NOT NULL,
    dependency_type smallint NOT NULL
);

CREATE SEQUENCE public.packages_dependency_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_dependency_links_id_seq OWNED BY public.packages_dependency_links.id;

CREATE TABLE public.packages_maven_metadata (
    id bigint NOT NULL,
    package_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    app_group character varying NOT NULL,
    app_name character varying NOT NULL,
    app_version character varying,
    path character varying(512) NOT NULL
);

CREATE SEQUENCE public.packages_maven_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_maven_metadata_id_seq OWNED BY public.packages_maven_metadata.id;

CREATE TABLE public.packages_nuget_dependency_link_metadata (
    dependency_link_id bigint NOT NULL,
    target_framework text NOT NULL,
    CONSTRAINT packages_nuget_dependency_link_metadata_target_framework_constr CHECK ((char_length(target_framework) <= 255))
);

CREATE TABLE public.packages_nuget_metadata (
    package_id bigint NOT NULL,
    license_url text,
    project_url text,
    icon_url text,
    CONSTRAINT packages_nuget_metadata_icon_url_constraint CHECK ((char_length(icon_url) <= 255)),
    CONSTRAINT packages_nuget_metadata_license_url_constraint CHECK ((char_length(license_url) <= 255)),
    CONSTRAINT packages_nuget_metadata_project_url_constraint CHECK ((char_length(project_url) <= 255))
);

CREATE TABLE public.packages_package_files (
    id bigint NOT NULL,
    package_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    size bigint,
    file_store integer,
    file_md5 bytea,
    file_sha1 bytea,
    file_name character varying NOT NULL,
    file text NOT NULL,
    file_sha256 bytea,
    verification_retry_at timestamp with time zone,
    verified_at timestamp with time zone,
    verification_failure character varying(255),
    verification_retry_count integer,
    verification_checksum bytea
);

CREATE SEQUENCE public.packages_package_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_package_files_id_seq OWNED BY public.packages_package_files.id;

CREATE TABLE public.packages_packages (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying NOT NULL,
    version character varying,
    package_type smallint NOT NULL
);

CREATE SEQUENCE public.packages_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_packages_id_seq OWNED BY public.packages_packages.id;

CREATE TABLE public.packages_pypi_metadata (
    package_id bigint NOT NULL,
    required_python character varying(50) NOT NULL
);

CREATE TABLE public.packages_tags (
    id bigint NOT NULL,
    package_id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.packages_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.packages_tags_id_seq OWNED BY public.packages_tags.id;

CREATE TABLE public.pages_domain_acme_orders (
    id bigint NOT NULL,
    pages_domain_id integer NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    url character varying NOT NULL,
    challenge_token character varying NOT NULL,
    challenge_file_content text NOT NULL,
    encrypted_private_key text NOT NULL,
    encrypted_private_key_iv text NOT NULL
);

CREATE SEQUENCE public.pages_domain_acme_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.pages_domain_acme_orders_id_seq OWNED BY public.pages_domain_acme_orders.id;

CREATE TABLE public.pages_domains (
    id integer NOT NULL,
    project_id integer,
    certificate text,
    encrypted_key text,
    encrypted_key_iv character varying,
    encrypted_key_salt character varying,
    domain character varying,
    verified_at timestamp with time zone,
    verification_code character varying NOT NULL,
    enabled_until timestamp with time zone,
    remove_at timestamp with time zone,
    auto_ssl_enabled boolean DEFAULT false NOT NULL,
    certificate_valid_not_before timestamp with time zone,
    certificate_valid_not_after timestamp with time zone,
    certificate_source smallint DEFAULT 0 NOT NULL,
    wildcard boolean DEFAULT false NOT NULL,
    usage smallint DEFAULT 0 NOT NULL,
    scope smallint DEFAULT 2 NOT NULL,
    auto_ssl_failed boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.pages_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.pages_domains_id_seq OWNED BY public.pages_domains.id;

CREATE TABLE public.partitioned_foreign_keys (
    id bigint NOT NULL,
    cascade_delete boolean DEFAULT true NOT NULL,
    from_table text NOT NULL,
    from_column text NOT NULL,
    to_table text NOT NULL,
    to_column text NOT NULL,
    CONSTRAINT check_2c2e02a62b CHECK ((char_length(from_column) <= 63)),
    CONSTRAINT check_40738efb57 CHECK ((char_length(to_table) <= 63)),
    CONSTRAINT check_741676d405 CHECK ((char_length(from_table) <= 63)),
    CONSTRAINT check_7e98be694f CHECK ((char_length(to_column) <= 63))
);

CREATE SEQUENCE public.partitioned_foreign_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.partitioned_foreign_keys_id_seq OWNED BY public.partitioned_foreign_keys.id;

CREATE TABLE public.path_locks (
    id integer NOT NULL,
    path character varying NOT NULL,
    project_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.path_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.path_locks_id_seq OWNED BY public.path_locks.id;

CREATE TABLE public.personal_access_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    revoked boolean DEFAULT false,
    expires_at date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    scopes character varying DEFAULT '--- []
'::character varying NOT NULL,
    impersonation boolean DEFAULT false NOT NULL,
    token_digest character varying,
    expire_notification_delivered boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;

CREATE TABLE public.plan_limits (
    id bigint NOT NULL,
    plan_id bigint NOT NULL,
    ci_active_pipelines integer DEFAULT 0 NOT NULL,
    ci_pipeline_size integer DEFAULT 0 NOT NULL,
    ci_active_jobs integer DEFAULT 0 NOT NULL,
    project_hooks integer DEFAULT 100 NOT NULL,
    group_hooks integer DEFAULT 50 NOT NULL,
    ci_project_subscriptions integer DEFAULT 2 NOT NULL,
    ci_pipeline_schedules integer DEFAULT 10 NOT NULL,
    offset_pagination_limit integer DEFAULT 50000 NOT NULL,
    ci_instance_level_variables integer DEFAULT 25 NOT NULL
);

CREATE SEQUENCE public.plan_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.plan_limits_id_seq OWNED BY public.plan_limits.id;

CREATE TABLE public.plans (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying,
    title character varying
);

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;

CREATE TABLE public.pool_repositories (
    id bigint NOT NULL,
    shard_id integer NOT NULL,
    disk_path character varying,
    state character varying,
    source_project_id integer
);

CREATE SEQUENCE public.pool_repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.pool_repositories_id_seq OWNED BY public.pool_repositories.id;

CREATE TABLE public.programming_languages (
    id integer NOT NULL,
    name character varying NOT NULL,
    color character varying NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.programming_languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.programming_languages_id_seq OWNED BY public.programming_languages.id;

CREATE TABLE public.project_alerting_settings (
    project_id integer NOT NULL,
    encrypted_token character varying NOT NULL,
    encrypted_token_iv character varying NOT NULL
);

CREATE TABLE public.project_aliases (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.project_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_aliases_id_seq OWNED BY public.project_aliases.id;

CREATE TABLE public.project_authorizations (
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    access_level integer NOT NULL
);

CREATE TABLE public.project_auto_devops (
    id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    enabled boolean,
    deploy_strategy integer DEFAULT 0 NOT NULL
);

CREATE SEQUENCE public.project_auto_devops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_auto_devops_id_seq OWNED BY public.project_auto_devops.id;

CREATE TABLE public.project_ci_cd_settings (
    id integer NOT NULL,
    project_id integer NOT NULL,
    group_runners_enabled boolean DEFAULT true NOT NULL,
    merge_pipelines_enabled boolean,
    default_git_depth integer,
    forward_deployment_enabled boolean
);

CREATE SEQUENCE public.project_ci_cd_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_ci_cd_settings_id_seq OWNED BY public.project_ci_cd_settings.id;

CREATE TABLE public.project_compliance_framework_settings (
    project_id bigint NOT NULL,
    framework smallint NOT NULL
);

CREATE SEQUENCE public.project_compliance_framework_settings_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_compliance_framework_settings_project_id_seq OWNED BY public.project_compliance_framework_settings.project_id;

CREATE TABLE public.project_custom_attributes (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    key character varying NOT NULL,
    value character varying NOT NULL
);

CREATE SEQUENCE public.project_custom_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_custom_attributes_id_seq OWNED BY public.project_custom_attributes.id;

CREATE TABLE public.project_daily_statistics (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    fetch_count integer NOT NULL,
    date date
);

CREATE SEQUENCE public.project_daily_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_daily_statistics_id_seq OWNED BY public.project_daily_statistics.id;

CREATE TABLE public.project_deploy_tokens (
    id integer NOT NULL,
    project_id integer NOT NULL,
    deploy_token_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.project_deploy_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_deploy_tokens_id_seq OWNED BY public.project_deploy_tokens.id;

CREATE TABLE public.project_error_tracking_settings (
    project_id integer NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    api_url character varying,
    encrypted_token character varying,
    encrypted_token_iv character varying,
    project_name character varying,
    organization_name character varying
);

CREATE TABLE public.project_export_jobs (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    jid character varying(100) NOT NULL
);

CREATE SEQUENCE public.project_export_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_export_jobs_id_seq OWNED BY public.project_export_jobs.id;

CREATE TABLE public.project_feature_usages (
    project_id integer NOT NULL,
    jira_dvcs_cloud_last_sync_at timestamp without time zone,
    jira_dvcs_server_last_sync_at timestamp without time zone
);

CREATE TABLE public.project_features (
    id integer NOT NULL,
    project_id integer NOT NULL,
    merge_requests_access_level integer,
    issues_access_level integer,
    wiki_access_level integer,
    snippets_access_level integer DEFAULT 20 NOT NULL,
    builds_access_level integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    repository_access_level integer DEFAULT 20 NOT NULL,
    pages_access_level integer NOT NULL,
    forking_access_level integer,
    metrics_dashboard_access_level integer
);

CREATE SEQUENCE public.project_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_features_id_seq OWNED BY public.project_features.id;

CREATE TABLE public.project_group_links (
    id integer NOT NULL,
    project_id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    group_access integer DEFAULT 30 NOT NULL,
    expires_at date
);

CREATE SEQUENCE public.project_group_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_group_links_id_seq OWNED BY public.project_group_links.id;

CREATE TABLE public.project_import_data (
    id integer NOT NULL,
    project_id integer,
    data text,
    encrypted_credentials text,
    encrypted_credentials_iv character varying,
    encrypted_credentials_salt character varying
);

CREATE SEQUENCE public.project_import_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_import_data_id_seq OWNED BY public.project_import_data.id;

CREATE TABLE public.project_incident_management_settings (
    project_id integer NOT NULL,
    create_issue boolean DEFAULT false NOT NULL,
    send_email boolean DEFAULT false NOT NULL,
    issue_template_key text
);

CREATE SEQUENCE public.project_incident_management_settings_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_incident_management_settings_project_id_seq OWNED BY public.project_incident_management_settings.project_id;

CREATE TABLE public.project_metrics_settings (
    project_id integer NOT NULL,
    external_dashboard_url character varying,
    dashboard_timezone smallint DEFAULT 0 NOT NULL
);

CREATE TABLE public.project_mirror_data (
    id integer NOT NULL,
    project_id integer NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    last_update_started_at timestamp without time zone,
    last_update_scheduled_at timestamp without time zone,
    next_execution_timestamp timestamp without time zone,
    status character varying,
    jid character varying,
    last_error text,
    last_update_at timestamp with time zone,
    last_successful_update_at timestamp with time zone,
    correlation_id_value character varying(128)
);

CREATE SEQUENCE public.project_mirror_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_mirror_data_id_seq OWNED BY public.project_mirror_data.id;

CREATE TABLE public.project_pages_metadata (
    project_id bigint NOT NULL,
    deployed boolean DEFAULT false NOT NULL
);

CREATE TABLE public.project_repositories (
    id bigint NOT NULL,
    shard_id integer NOT NULL,
    disk_path character varying NOT NULL,
    project_id integer NOT NULL
);

CREATE SEQUENCE public.project_repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_repositories_id_seq OWNED BY public.project_repositories.id;

CREATE TABLE public.project_repository_states (
    id integer NOT NULL,
    project_id integer NOT NULL,
    repository_verification_checksum bytea,
    wiki_verification_checksum bytea,
    last_repository_verification_failure character varying,
    last_wiki_verification_failure character varying,
    repository_retry_at timestamp with time zone,
    wiki_retry_at timestamp with time zone,
    repository_retry_count integer,
    wiki_retry_count integer,
    last_repository_verification_ran_at timestamp with time zone,
    last_wiki_verification_ran_at timestamp with time zone
);

CREATE SEQUENCE public.project_repository_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_repository_states_id_seq OWNED BY public.project_repository_states.id;

CREATE TABLE public.project_repository_storage_moves (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id bigint NOT NULL,
    state smallint DEFAULT 1 NOT NULL,
    source_storage_name text NOT NULL,
    destination_storage_name text NOT NULL,
    CONSTRAINT project_repository_storage_moves_destination_storage_name CHECK ((char_length(destination_storage_name) <= 255)),
    CONSTRAINT project_repository_storage_moves_source_storage_name CHECK ((char_length(source_storage_name) <= 255))
);

CREATE SEQUENCE public.project_repository_storage_moves_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_repository_storage_moves_id_seq OWNED BY public.project_repository_storage_moves.id;

CREATE TABLE public.project_security_settings (
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    auto_fix_container_scanning boolean DEFAULT true NOT NULL,
    auto_fix_dast boolean DEFAULT true NOT NULL,
    auto_fix_dependency_scanning boolean DEFAULT true NOT NULL,
    auto_fix_sast boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.project_security_settings_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_security_settings_project_id_seq OWNED BY public.project_security_settings.project_id;

CREATE TABLE public.project_settings (
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    push_rule_id bigint,
    show_default_award_emojis boolean DEFAULT true,
    allow_merge_on_skipped_pipeline boolean,
    CONSTRAINT check_bde223416c CHECK ((show_default_award_emojis IS NOT NULL))
);

CREATE TABLE public.project_statistics (
    id integer NOT NULL,
    project_id integer NOT NULL,
    namespace_id integer NOT NULL,
    commit_count bigint DEFAULT 0 NOT NULL,
    storage_size bigint DEFAULT 0 NOT NULL,
    repository_size bigint DEFAULT 0 NOT NULL,
    lfs_objects_size bigint DEFAULT 0 NOT NULL,
    build_artifacts_size bigint DEFAULT 0 NOT NULL,
    shared_runners_seconds bigint DEFAULT 0 NOT NULL,
    shared_runners_seconds_last_reset timestamp without time zone,
    packages_size bigint DEFAULT 0 NOT NULL,
    wiki_size bigint
);

CREATE SEQUENCE public.project_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_statistics_id_seq OWNED BY public.project_statistics.id;

CREATE TABLE public.project_tracing_settings (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    external_url character varying NOT NULL
);

CREATE SEQUENCE public.project_tracing_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.project_tracing_settings_id_seq OWNED BY public.project_tracing_settings.id;

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying,
    path character varying,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    creator_id integer,
    namespace_id integer NOT NULL,
    last_activity_at timestamp without time zone,
    import_url character varying,
    visibility_level integer DEFAULT 0 NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    avatar character varying,
    merge_requests_template text,
    star_count integer DEFAULT 0 NOT NULL,
    merge_requests_rebase_enabled boolean DEFAULT false,
    import_type character varying,
    import_source character varying,
    approvals_before_merge integer DEFAULT 0 NOT NULL,
    reset_approvals_on_push boolean DEFAULT true,
    merge_requests_ff_only_enabled boolean DEFAULT false,
    issues_template text,
    mirror boolean DEFAULT false NOT NULL,
    mirror_last_update_at timestamp without time zone,
    mirror_last_successful_update_at timestamp without time zone,
    mirror_user_id integer,
    shared_runners_enabled boolean DEFAULT true NOT NULL,
    runners_token character varying,
    build_coverage_regex character varying,
    build_allow_git_fetch boolean DEFAULT true NOT NULL,
    build_timeout integer DEFAULT 3600 NOT NULL,
    mirror_trigger_builds boolean DEFAULT false NOT NULL,
    pending_delete boolean DEFAULT false,
    public_builds boolean DEFAULT true NOT NULL,
    last_repository_check_failed boolean,
    last_repository_check_at timestamp without time zone,
    container_registry_enabled boolean,
    only_allow_merge_if_pipeline_succeeds boolean DEFAULT false NOT NULL,
    has_external_issue_tracker boolean,
    repository_storage character varying DEFAULT 'default'::character varying NOT NULL,
    repository_read_only boolean,
    request_access_enabled boolean DEFAULT true NOT NULL,
    has_external_wiki boolean,
    ci_config_path character varying,
    lfs_enabled boolean,
    description_html text,
    only_allow_merge_if_all_discussions_are_resolved boolean,
    repository_size_limit bigint,
    printing_merge_request_link_enabled boolean DEFAULT true NOT NULL,
    auto_cancel_pending_pipelines integer DEFAULT 1 NOT NULL,
    service_desk_enabled boolean DEFAULT true,
    cached_markdown_version integer,
    delete_error text,
    last_repository_updated_at timestamp without time zone,
    disable_overriding_approvers_per_merge_request boolean,
    storage_version smallint,
    resolve_outdated_diff_discussions boolean,
    remote_mirror_available_overridden boolean,
    only_mirror_protected_branches boolean,
    pull_mirror_available_overridden boolean,
    jobs_cache_index integer,
    external_authorization_classification_label character varying,
    mirror_overwrites_diverged_branches boolean,
    pages_https_only boolean DEFAULT true,
    external_webhook_token character varying,
    packages_enabled boolean,
    merge_requests_author_approval boolean,
    pool_repository_id bigint,
    runners_token_encrypted character varying,
    bfg_object_map character varying,
    detected_repository_languages boolean,
    merge_requests_disable_committers_approval boolean,
    require_password_to_approve boolean,
    emails_disabled boolean,
    max_pages_size integer,
    max_artifacts_size integer,
    pull_mirror_branch_prefix character varying(50),
    remove_source_branch_after_merge boolean,
    marked_for_deletion_at date,
    marked_for_deletion_by_user_id integer,
    autoclose_referenced_issues boolean,
    suggestion_commit_message character varying(255)
);

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;

CREATE TABLE public.prometheus_alert_events (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    prometheus_alert_id integer NOT NULL,
    started_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    status smallint,
    payload_key character varying
);

CREATE SEQUENCE public.prometheus_alert_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.prometheus_alert_events_id_seq OWNED BY public.prometheus_alert_events.id;

CREATE TABLE public.prometheus_alerts (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    threshold double precision NOT NULL,
    operator integer NOT NULL,
    environment_id integer NOT NULL,
    project_id integer NOT NULL,
    prometheus_metric_id integer NOT NULL
);

CREATE SEQUENCE public.prometheus_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.prometheus_alerts_id_seq OWNED BY public.prometheus_alerts.id;

CREATE TABLE public.prometheus_metrics (
    id integer NOT NULL,
    project_id integer,
    title character varying NOT NULL,
    query character varying NOT NULL,
    y_label character varying NOT NULL,
    unit character varying NOT NULL,
    legend character varying,
    "group" integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    common boolean DEFAULT false NOT NULL,
    identifier character varying
);

CREATE SEQUENCE public.prometheus_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.prometheus_metrics_id_seq OWNED BY public.prometheus_metrics.id;

CREATE TABLE public.protected_branch_merge_access_levels (
    id integer NOT NULL,
    protected_branch_id integer NOT NULL,
    access_level integer DEFAULT 40,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    group_id integer
);

CREATE SEQUENCE public.protected_branch_merge_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_branch_merge_access_levels_id_seq OWNED BY public.protected_branch_merge_access_levels.id;

CREATE TABLE public.protected_branch_push_access_levels (
    id integer NOT NULL,
    protected_branch_id integer NOT NULL,
    access_level integer DEFAULT 40,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    group_id integer
);

CREATE SEQUENCE public.protected_branch_push_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_branch_push_access_levels_id_seq OWNED BY public.protected_branch_push_access_levels.id;

CREATE TABLE public.protected_branch_unprotect_access_levels (
    id integer NOT NULL,
    protected_branch_id integer NOT NULL,
    access_level integer DEFAULT 40,
    user_id integer,
    group_id integer
);

CREATE SEQUENCE public.protected_branch_unprotect_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_branch_unprotect_access_levels_id_seq OWNED BY public.protected_branch_unprotect_access_levels.id;

CREATE TABLE public.protected_branches (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    code_owner_approval_required boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.protected_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_branches_id_seq OWNED BY public.protected_branches.id;

CREATE TABLE public.protected_environment_deploy_access_levels (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    access_level integer DEFAULT 40,
    protected_environment_id integer NOT NULL,
    user_id integer,
    group_id integer
);

CREATE SEQUENCE public.protected_environment_deploy_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_environment_deploy_access_levels_id_seq OWNED BY public.protected_environment_deploy_access_levels.id;

CREATE TABLE public.protected_environments (
    id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying NOT NULL
);

CREATE SEQUENCE public.protected_environments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_environments_id_seq OWNED BY public.protected_environments.id;

CREATE TABLE public.protected_tag_create_access_levels (
    id integer NOT NULL,
    protected_tag_id integer NOT NULL,
    access_level integer DEFAULT 40,
    user_id integer,
    group_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.protected_tag_create_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_tag_create_access_levels_id_seq OWNED BY public.protected_tag_create_access_levels.id;

CREATE TABLE public.protected_tags (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.protected_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.protected_tags_id_seq OWNED BY public.protected_tags.id;

CREATE TABLE public.push_event_payloads (
    commit_count bigint NOT NULL,
    event_id integer NOT NULL,
    action smallint NOT NULL,
    ref_type smallint NOT NULL,
    commit_from bytea,
    commit_to bytea,
    ref text,
    commit_title character varying(70),
    ref_count integer
);

CREATE TABLE public.push_rules (
    id integer NOT NULL,
    force_push_regex character varying,
    delete_branch_regex character varying,
    commit_message_regex character varying,
    deny_delete_tag boolean,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    author_email_regex character varying,
    member_check boolean DEFAULT false NOT NULL,
    file_name_regex character varying,
    is_sample boolean DEFAULT false,
    max_file_size integer DEFAULT 0 NOT NULL,
    prevent_secrets boolean DEFAULT false NOT NULL,
    branch_name_regex character varying,
    reject_unsigned_commits boolean,
    commit_committer_check boolean,
    regexp_uses_re2 boolean DEFAULT true,
    commit_message_negative_regex character varying
);

CREATE SEQUENCE public.push_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.push_rules_id_seq OWNED BY public.push_rules.id;

CREATE TABLE public.redirect_routes (
    id integer NOT NULL,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    path character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.redirect_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.redirect_routes_id_seq OWNED BY public.redirect_routes.id;

CREATE TABLE public.release_links (
    id bigint NOT NULL,
    release_id integer NOT NULL,
    url character varying NOT NULL,
    name character varying NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    filepath character varying(128),
    link_type smallint DEFAULT 0
);

CREATE SEQUENCE public.release_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.release_links_id_seq OWNED BY public.release_links.id;

CREATE TABLE public.releases (
    id integer NOT NULL,
    tag character varying,
    description text,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description_html text,
    cached_markdown_version integer,
    author_id integer,
    name character varying,
    sha character varying,
    released_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.releases_id_seq OWNED BY public.releases.id;

CREATE TABLE public.remote_mirrors (
    id integer NOT NULL,
    project_id integer,
    url character varying,
    enabled boolean DEFAULT false,
    update_status character varying,
    last_update_at timestamp without time zone,
    last_successful_update_at timestamp without time zone,
    last_error character varying,
    encrypted_credentials text,
    encrypted_credentials_iv character varying,
    encrypted_credentials_salt character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_update_started_at timestamp without time zone,
    only_protected_branches boolean DEFAULT false NOT NULL,
    remote_name character varying,
    error_notification_sent boolean,
    keep_divergent_refs boolean
);

CREATE SEQUENCE public.remote_mirrors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.remote_mirrors_id_seq OWNED BY public.remote_mirrors.id;

CREATE TABLE public.repository_languages (
    project_id integer NOT NULL,
    programming_language_id integer NOT NULL,
    share double precision NOT NULL
);

CREATE TABLE public.requirements (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    author_id integer,
    iid integer NOT NULL,
    cached_markdown_version integer,
    state smallint DEFAULT 1 NOT NULL,
    title character varying(255) NOT NULL,
    title_html text
);

CREATE SEQUENCE public.requirements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.requirements_id_seq OWNED BY public.requirements.id;

CREATE TABLE public.requirements_management_test_reports (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    requirement_id bigint NOT NULL,
    pipeline_id bigint,
    author_id bigint,
    state smallint NOT NULL,
    build_id bigint
);

CREATE SEQUENCE public.requirements_management_test_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.requirements_management_test_reports_id_seq OWNED BY public.requirements_management_test_reports.id;

CREATE TABLE public.resource_label_events (
    id bigint NOT NULL,
    action integer NOT NULL,
    issue_id integer,
    merge_request_id integer,
    epic_id integer,
    label_id integer,
    user_id integer,
    created_at timestamp with time zone NOT NULL,
    cached_markdown_version integer,
    reference text,
    reference_html text
);

CREATE SEQUENCE public.resource_label_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.resource_label_events_id_seq OWNED BY public.resource_label_events.id;

CREATE TABLE public.resource_milestone_events (
    id bigint NOT NULL,
    user_id bigint,
    issue_id bigint,
    merge_request_id bigint,
    milestone_id bigint,
    action smallint NOT NULL,
    state smallint NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.resource_milestone_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.resource_milestone_events_id_seq OWNED BY public.resource_milestone_events.id;

CREATE TABLE public.resource_state_events (
    id bigint NOT NULL,
    user_id bigint,
    issue_id bigint,
    merge_request_id bigint,
    created_at timestamp with time zone NOT NULL,
    state smallint NOT NULL,
    epic_id integer,
    CONSTRAINT state_events_must_belong_to_issue_or_merge_request_or_epic CHECK ((((issue_id <> NULL::bigint) AND (merge_request_id IS NULL) AND (epic_id IS NULL)) OR ((issue_id IS NULL) AND (merge_request_id <> NULL::bigint) AND (epic_id IS NULL)) OR ((issue_id IS NULL) AND (merge_request_id IS NULL) AND (epic_id <> NULL::integer))))
);

CREATE SEQUENCE public.resource_state_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.resource_state_events_id_seq OWNED BY public.resource_state_events.id;

CREATE TABLE public.resource_weight_events (
    id bigint NOT NULL,
    user_id bigint,
    issue_id bigint NOT NULL,
    weight integer,
    created_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.resource_weight_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.resource_weight_events_id_seq OWNED BY public.resource_weight_events.id;

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    author_id integer,
    merge_request_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;

CREATE TABLE public.routes (
    id integer NOT NULL,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    path character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying
);

CREATE SEQUENCE public.routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.routes_id_seq OWNED BY public.routes.id;

CREATE TABLE public.saml_providers (
    id integer NOT NULL,
    group_id integer NOT NULL,
    enabled boolean NOT NULL,
    certificate_fingerprint character varying NOT NULL,
    sso_url character varying NOT NULL,
    enforced_sso boolean DEFAULT false NOT NULL,
    enforced_group_managed_accounts boolean DEFAULT false NOT NULL,
    prohibited_outer_forks boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.saml_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.saml_providers_id_seq OWNED BY public.saml_providers.id;

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);

CREATE TABLE public.scim_identities (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    active boolean DEFAULT false,
    extern_uid character varying(255) NOT NULL
);

CREATE SEQUENCE public.scim_identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.scim_identities_id_seq OWNED BY public.scim_identities.id;

CREATE TABLE public.scim_oauth_access_tokens (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    group_id integer NOT NULL,
    token_encrypted character varying NOT NULL
);

CREATE SEQUENCE public.scim_oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.scim_oauth_access_tokens_id_seq OWNED BY public.scim_oauth_access_tokens.id;

CREATE TABLE public.security_scans (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    build_id bigint NOT NULL,
    scan_type smallint NOT NULL,
    scanned_resources_count integer
);

CREATE SEQUENCE public.security_scans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.security_scans_id_seq OWNED BY public.security_scans.id;

CREATE TABLE public.self_managed_prometheus_alert_events (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    environment_id bigint,
    started_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    status smallint NOT NULL,
    title character varying(255) NOT NULL,
    query_expression character varying(255),
    payload_key character varying(255) NOT NULL
);

CREATE SEQUENCE public.self_managed_prometheus_alert_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.self_managed_prometheus_alert_events_id_seq OWNED BY public.self_managed_prometheus_alert_events.id;

CREATE TABLE public.sent_notifications (
    id integer NOT NULL,
    project_id integer,
    noteable_id integer,
    noteable_type character varying,
    recipient_id integer,
    commit_id character varying,
    reply_key character varying NOT NULL,
    line_code character varying,
    note_type character varying,
    "position" text,
    in_reply_to_discussion_id character varying
);

CREATE SEQUENCE public.sent_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.sent_notifications_id_seq OWNED BY public.sent_notifications.id;

CREATE TABLE public.sentry_issues (
    id bigint NOT NULL,
    issue_id bigint NOT NULL,
    sentry_issue_identifier bigint NOT NULL
);

CREATE SEQUENCE public.sentry_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.sentry_issues_id_seq OWNED BY public.sentry_issues.id;

CREATE TABLE public.serverless_domain_cluster (
    uuid character varying(14) NOT NULL,
    pages_domain_id bigint NOT NULL,
    clusters_applications_knative_id bigint NOT NULL,
    creator_id bigint,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    encrypted_key text,
    encrypted_key_iv character varying(255),
    certificate text
);

CREATE TABLE public.service_desk_settings (
    project_id bigint NOT NULL,
    issue_template_key character varying(255),
    outgoing_name character varying(255),
    project_key character varying(255)
);

CREATE TABLE public.services (
    id integer NOT NULL,
    type character varying,
    title character varying,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    active boolean DEFAULT false NOT NULL,
    properties text,
    push_events boolean DEFAULT true,
    issues_events boolean DEFAULT true,
    merge_requests_events boolean DEFAULT true,
    tag_push_events boolean DEFAULT true,
    note_events boolean DEFAULT true NOT NULL,
    category character varying DEFAULT 'common'::character varying NOT NULL,
    "default" boolean DEFAULT false,
    wiki_page_events boolean DEFAULT true,
    pipeline_events boolean DEFAULT false NOT NULL,
    confidential_issues_events boolean DEFAULT true NOT NULL,
    commit_events boolean DEFAULT true NOT NULL,
    job_events boolean DEFAULT false NOT NULL,
    confidential_note_events boolean DEFAULT true,
    deployment_events boolean DEFAULT false NOT NULL,
    description character varying(500),
    comment_on_event_enabled boolean DEFAULT true NOT NULL,
    template boolean DEFAULT false,
    instance boolean DEFAULT false NOT NULL,
    comment_detail smallint,
    inherit_from_id bigint,
    alert_events boolean
);

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;

CREATE TABLE public.shards (
    id integer NOT NULL,
    name character varying NOT NULL
);

CREATE SEQUENCE public.shards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.shards_id_seq OWNED BY public.shards.id;

CREATE TABLE public.slack_integrations (
    id integer NOT NULL,
    service_id integer NOT NULL,
    team_id character varying NOT NULL,
    team_name character varying NOT NULL,
    alias character varying NOT NULL,
    user_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.slack_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.slack_integrations_id_seq OWNED BY public.slack_integrations.id;

CREATE TABLE public.smartcard_identities (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    subject character varying NOT NULL,
    issuer character varying NOT NULL
);

CREATE SEQUENCE public.smartcard_identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.smartcard_identities_id_seq OWNED BY public.smartcard_identities.id;

CREATE TABLE public.snippet_repositories (
    snippet_id bigint NOT NULL,
    shard_id bigint NOT NULL,
    disk_path character varying(80) NOT NULL
);

CREATE TABLE public.snippet_user_mentions (
    id bigint NOT NULL,
    snippet_id integer NOT NULL,
    note_id integer,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.snippet_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.snippet_user_mentions_id_seq OWNED BY public.snippet_user_mentions.id;

CREATE TABLE public.snippets (
    id integer NOT NULL,
    title character varying,
    content text,
    author_id integer NOT NULL,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    file_name character varying,
    type character varying,
    visibility_level integer DEFAULT 0 NOT NULL,
    title_html text,
    content_html text,
    cached_markdown_version integer,
    description text,
    description_html text,
    encrypted_secret_token character varying(255),
    encrypted_secret_token_iv character varying(255),
    secret boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.snippets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.snippets_id_seq OWNED BY public.snippets.id;

CREATE TABLE public.software_license_policies (
    id integer NOT NULL,
    project_id integer NOT NULL,
    software_license_id integer NOT NULL,
    classification integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.software_license_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.software_license_policies_id_seq OWNED BY public.software_license_policies.id;

CREATE TABLE public.software_licenses (
    id integer NOT NULL,
    name character varying NOT NULL,
    spdx_identifier character varying(255)
);

CREATE SEQUENCE public.software_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.software_licenses_id_seq OWNED BY public.software_licenses.id;

CREATE TABLE public.spam_logs (
    id integer NOT NULL,
    user_id integer,
    source_ip character varying,
    user_agent character varying,
    via_api boolean,
    noteable_type character varying,
    title character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submitted_as_ham boolean DEFAULT false NOT NULL,
    recaptcha_verified boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.spam_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.spam_logs_id_seq OWNED BY public.spam_logs.id;

CREATE TABLE public.sprints (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    start_date date,
    due_date date,
    project_id bigint,
    group_id bigint,
    iid integer NOT NULL,
    cached_markdown_version integer,
    title text NOT NULL,
    title_html text,
    description text,
    description_html text,
    state_enum smallint DEFAULT 1 NOT NULL,
    CONSTRAINT sprints_must_belong_to_project_or_group CHECK ((((project_id <> NULL::bigint) AND (group_id IS NULL)) OR ((group_id <> NULL::bigint) AND (project_id IS NULL)))),
    CONSTRAINT sprints_title CHECK ((char_length(title) <= 255))
);

CREATE SEQUENCE public.sprints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.sprints_id_seq OWNED BY public.sprints.id;

CREATE TABLE public.status_page_published_incidents (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    issue_id bigint NOT NULL
);

CREATE SEQUENCE public.status_page_published_incidents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.status_page_published_incidents_id_seq OWNED BY public.status_page_published_incidents.id;

CREATE TABLE public.status_page_settings (
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    aws_s3_bucket_name character varying(63) NOT NULL,
    aws_region character varying(255) NOT NULL,
    aws_access_key character varying(255) NOT NULL,
    encrypted_aws_secret_key character varying(255) NOT NULL,
    encrypted_aws_secret_key_iv character varying(255) NOT NULL,
    status_page_url text,
    CONSTRAINT check_75a79cd992 CHECK ((char_length(status_page_url) <= 1024))
);

CREATE SEQUENCE public.status_page_settings_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.status_page_settings_project_id_seq OWNED BY public.status_page_settings.project_id;

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    user_id integer,
    subscribable_id integer,
    subscribable_type character varying,
    subscribed boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer
);

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;

CREATE TABLE public.suggestions (
    id bigint NOT NULL,
    note_id integer NOT NULL,
    relative_order smallint NOT NULL,
    applied boolean DEFAULT false NOT NULL,
    commit_id character varying,
    from_content text NOT NULL,
    to_content text NOT NULL,
    lines_above integer DEFAULT 0 NOT NULL,
    lines_below integer DEFAULT 0 NOT NULL,
    outdated boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE public.suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.suggestions_id_seq OWNED BY public.suggestions.id;

CREATE TABLE public.system_note_metadata (
    id integer NOT NULL,
    note_id integer NOT NULL,
    commit_count integer,
    action character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description_version_id bigint
);

CREATE SEQUENCE public.system_note_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.system_note_metadata_id_seq OWNED BY public.system_note_metadata.id;

CREATE TABLE public.taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying,
    tagger_id integer,
    tagger_type character varying,
    context character varying,
    created_at timestamp without time zone
);

CREATE SEQUENCE public.taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying,
    taggings_count integer DEFAULT 0
);

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;

CREATE TABLE public.term_agreements (
    id integer NOT NULL,
    term_id integer NOT NULL,
    user_id integer NOT NULL,
    accepted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.term_agreements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.term_agreements_id_seq OWNED BY public.term_agreements.id;

CREATE TABLE public.terraform_states (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    file_store smallint,
    file character varying(255),
    lock_xid character varying(255),
    locked_at timestamp with time zone,
    locked_by_user_id bigint,
    uuid character varying(32) NOT NULL,
    name character varying(255)
);

CREATE SEQUENCE public.terraform_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.terraform_states_id_seq OWNED BY public.terraform_states.id;

CREATE TABLE public.timelogs (
    id integer NOT NULL,
    time_spent integer NOT NULL,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    issue_id integer,
    merge_request_id integer,
    spent_at timestamp without time zone
);

CREATE SEQUENCE public.timelogs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.timelogs_id_seq OWNED BY public.timelogs.id;

CREATE TABLE public.todos (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer,
    target_id integer,
    target_type character varying NOT NULL,
    author_id integer NOT NULL,
    action integer NOT NULL,
    state character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    note_id integer,
    commit_id character varying,
    group_id integer,
    resolved_by_action smallint
);

CREATE SEQUENCE public.todos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.todos_id_seq OWNED BY public.todos.id;

CREATE TABLE public.trending_projects (
    id integer NOT NULL,
    project_id integer NOT NULL
);

CREATE SEQUENCE public.trending_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.trending_projects_id_seq OWNED BY public.trending_projects.id;

CREATE TABLE public.u2f_registrations (
    id integer NOT NULL,
    certificate text,
    key_handle character varying,
    public_key character varying,
    counter integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying
);

CREATE SEQUENCE public.u2f_registrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.u2f_registrations_id_seq OWNED BY public.u2f_registrations.id;

CREATE TABLE public.uploads (
    id integer NOT NULL,
    size bigint NOT NULL,
    path character varying(511) NOT NULL,
    checksum character varying(64),
    model_id integer,
    model_type character varying,
    uploader character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    store integer DEFAULT 1,
    mount_point character varying,
    secret character varying
);

CREATE SEQUENCE public.uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.uploads_id_seq OWNED BY public.uploads.id;

CREATE TABLE public.user_agent_details (
    id integer NOT NULL,
    user_agent character varying NOT NULL,
    ip_address character varying NOT NULL,
    subject_id integer NOT NULL,
    subject_type character varying NOT NULL,
    submitted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.user_agent_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_agent_details_id_seq OWNED BY public.user_agent_details.id;

CREATE TABLE public.user_callouts (
    id integer NOT NULL,
    feature_name integer NOT NULL,
    user_id integer NOT NULL,
    dismissed_at timestamp with time zone
);

CREATE SEQUENCE public.user_callouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_callouts_id_seq OWNED BY public.user_callouts.id;

CREATE TABLE public.user_canonical_emails (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id bigint NOT NULL,
    canonical_email character varying NOT NULL
);

CREATE SEQUENCE public.user_canonical_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_canonical_emails_id_seq OWNED BY public.user_canonical_emails.id;

CREATE TABLE public.user_custom_attributes (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    key character varying NOT NULL,
    value character varying NOT NULL
);

CREATE SEQUENCE public.user_custom_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_custom_attributes_id_seq OWNED BY public.user_custom_attributes.id;

CREATE TABLE public.user_details (
    user_id bigint NOT NULL,
    job_title character varying(200) DEFAULT ''::character varying NOT NULL,
    bio character varying(255) DEFAULT ''::character varying NOT NULL
);

CREATE SEQUENCE public.user_details_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_details_user_id_seq OWNED BY public.user_details.user_id;

CREATE TABLE public.user_highest_roles (
    user_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    highest_access_level integer
);

CREATE TABLE public.user_interacted_projects (
    user_id integer NOT NULL,
    project_id integer NOT NULL
);

CREATE TABLE public.user_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    issue_notes_filter smallint DEFAULT 0 NOT NULL,
    merge_request_notes_filter smallint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    epics_sort character varying,
    roadmap_epics_state integer,
    epic_notes_filter smallint DEFAULT 0 NOT NULL,
    issues_sort character varying,
    merge_requests_sort character varying,
    roadmaps_sort character varying,
    first_day_of_week integer,
    timezone character varying,
    time_display_relative boolean,
    time_format_in_24h boolean,
    projects_sort character varying(64),
    show_whitespace_in_diffs boolean DEFAULT true NOT NULL,
    sourcegraph_enabled boolean,
    setup_for_company boolean,
    render_whitespace_in_code boolean,
    tab_width smallint,
    feature_filter_type bigint,
    experience_level smallint
);

CREATE SEQUENCE public.user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_preferences_id_seq OWNED BY public.user_preferences.id;

CREATE TABLE public.user_statuses (
    user_id integer NOT NULL,
    cached_markdown_version integer,
    emoji character varying DEFAULT 'speech_balloon'::character varying NOT NULL,
    message character varying(100),
    message_html character varying
);

CREATE SEQUENCE public.user_statuses_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_statuses_user_id_seq OWNED BY public.user_statuses.user_id;

CREATE TABLE public.user_synced_attributes_metadata (
    id integer NOT NULL,
    name_synced boolean DEFAULT false,
    email_synced boolean DEFAULT false,
    location_synced boolean DEFAULT false,
    user_id integer NOT NULL,
    provider character varying
);

CREATE SEQUENCE public.user_synced_attributes_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.user_synced_attributes_metadata_id_seq OWNED BY public.user_synced_attributes_metadata.id;

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying,
    admin boolean DEFAULT false NOT NULL,
    projects_limit integer NOT NULL,
    skype character varying DEFAULT ''::character varying NOT NULL,
    linkedin character varying DEFAULT ''::character varying NOT NULL,
    twitter character varying DEFAULT ''::character varying NOT NULL,
    bio character varying,
    failed_attempts integer DEFAULT 0,
    locked_at timestamp without time zone,
    username character varying,
    can_create_group boolean DEFAULT true NOT NULL,
    can_create_team boolean DEFAULT true NOT NULL,
    state character varying,
    color_scheme_id integer DEFAULT 1 NOT NULL,
    password_expires_at timestamp without time zone,
    created_by_id integer,
    last_credential_check_at timestamp without time zone,
    avatar character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    hide_no_ssh_key boolean DEFAULT false,
    website_url character varying DEFAULT ''::character varying NOT NULL,
    admin_email_unsubscribed_at timestamp without time zone,
    notification_email character varying,
    hide_no_password boolean DEFAULT false,
    password_automatically_set boolean DEFAULT false,
    location character varying,
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    otp_required_for_login boolean DEFAULT false NOT NULL,
    otp_backup_codes text,
    public_email character varying DEFAULT ''::character varying NOT NULL,
    dashboard integer DEFAULT 0,
    project_view integer DEFAULT 0,
    consumed_timestep integer,
    layout integer DEFAULT 0,
    hide_project_limit boolean DEFAULT false,
    note text,
    unlock_token character varying,
    otp_grace_period_started_at timestamp without time zone,
    external boolean DEFAULT false,
    incoming_email_token character varying,
    organization character varying,
    auditor boolean DEFAULT false NOT NULL,
    require_two_factor_authentication_from_group boolean DEFAULT false NOT NULL,
    two_factor_grace_period integer DEFAULT 48 NOT NULL,
    last_activity_on date,
    notified_of_own_activity boolean,
    preferred_language character varying,
    email_opted_in boolean,
    email_opted_in_ip character varying,
    email_opted_in_source_id integer,
    email_opted_in_at timestamp without time zone,
    theme_id smallint,
    accepted_term_id integer,
    feed_token character varying,
    private_profile boolean DEFAULT false NOT NULL,
    roadmap_layout smallint,
    include_private_contributions boolean,
    commit_email character varying,
    group_view integer,
    managing_group_id integer,
    first_name character varying(255),
    last_name character varying(255),
    static_object_token character varying(255),
    role smallint,
    user_type smallint
);

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;

CREATE TABLE public.users_ops_dashboard_projects (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL
);

CREATE SEQUENCE public.users_ops_dashboard_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_ops_dashboard_projects_id_seq OWNED BY public.users_ops_dashboard_projects.id;

CREATE TABLE public.users_security_dashboard_projects (
    user_id bigint NOT NULL,
    project_id bigint NOT NULL
);

CREATE TABLE public.users_star_projects (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE SEQUENCE public.users_star_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_star_projects_id_seq OWNED BY public.users_star_projects.id;

CREATE TABLE public.users_statistics (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    without_groups_and_projects integer DEFAULT 0 NOT NULL,
    with_highest_role_guest integer DEFAULT 0 NOT NULL,
    with_highest_role_reporter integer DEFAULT 0 NOT NULL,
    with_highest_role_developer integer DEFAULT 0 NOT NULL,
    with_highest_role_maintainer integer DEFAULT 0 NOT NULL,
    with_highest_role_owner integer DEFAULT 0 NOT NULL,
    bots integer DEFAULT 0 NOT NULL,
    blocked integer DEFAULT 0 NOT NULL
);

CREATE SEQUENCE public.users_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_statistics_id_seq OWNED BY public.users_statistics.id;

CREATE TABLE public.vulnerabilities (
    id bigint NOT NULL,
    milestone_id bigint,
    epic_id bigint,
    project_id bigint NOT NULL,
    author_id bigint NOT NULL,
    updated_by_id bigint,
    last_edited_by_id bigint,
    start_date date,
    due_date date,
    last_edited_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    title character varying(255) NOT NULL,
    title_html text,
    description text,
    description_html text,
    start_date_sourcing_milestone_id bigint,
    due_date_sourcing_milestone_id bigint,
    state smallint DEFAULT 1 NOT NULL,
    severity smallint NOT NULL,
    severity_overridden boolean DEFAULT false,
    confidence smallint NOT NULL,
    confidence_overridden boolean DEFAULT false,
    resolved_by_id bigint,
    resolved_at timestamp with time zone,
    report_type smallint NOT NULL,
    cached_markdown_version integer,
    confirmed_by_id bigint,
    confirmed_at timestamp with time zone,
    dismissed_at timestamp with time zone,
    dismissed_by_id bigint
);

CREATE SEQUENCE public.vulnerabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerabilities_id_seq OWNED BY public.vulnerabilities.id;

CREATE TABLE public.vulnerability_exports (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    status character varying(255) NOT NULL,
    file character varying(255),
    project_id bigint,
    author_id bigint NOT NULL,
    file_store integer,
    format smallint DEFAULT 0 NOT NULL,
    group_id integer
);

CREATE SEQUENCE public.vulnerability_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_exports_id_seq OWNED BY public.vulnerability_exports.id;

CREATE TABLE public.vulnerability_feedback (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    feedback_type smallint NOT NULL,
    category smallint NOT NULL,
    project_id integer NOT NULL,
    author_id integer NOT NULL,
    pipeline_id integer,
    issue_id integer,
    project_fingerprint character varying(40) NOT NULL,
    merge_request_id integer,
    comment_author_id integer,
    comment text,
    comment_timestamp timestamp with time zone
);

CREATE SEQUENCE public.vulnerability_feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_feedback_id_seq OWNED BY public.vulnerability_feedback.id;

CREATE TABLE public.vulnerability_identifiers (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    fingerprint bytea NOT NULL,
    external_type character varying NOT NULL,
    external_id character varying NOT NULL,
    name character varying NOT NULL,
    url text
);

CREATE SEQUENCE public.vulnerability_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_identifiers_id_seq OWNED BY public.vulnerability_identifiers.id;

CREATE TABLE public.vulnerability_issue_links (
    id bigint NOT NULL,
    vulnerability_id bigint NOT NULL,
    issue_id bigint NOT NULL,
    link_type smallint DEFAULT 1 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE SEQUENCE public.vulnerability_issue_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_issue_links_id_seq OWNED BY public.vulnerability_issue_links.id;

CREATE TABLE public.vulnerability_occurrence_identifiers (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    occurrence_id bigint NOT NULL,
    identifier_id bigint NOT NULL
);

CREATE SEQUENCE public.vulnerability_occurrence_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_occurrence_identifiers_id_seq OWNED BY public.vulnerability_occurrence_identifiers.id;

CREATE TABLE public.vulnerability_occurrence_pipelines (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    occurrence_id bigint NOT NULL,
    pipeline_id integer NOT NULL
);

CREATE SEQUENCE public.vulnerability_occurrence_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_occurrence_pipelines_id_seq OWNED BY public.vulnerability_occurrence_pipelines.id;

CREATE TABLE public.vulnerability_occurrences (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    severity smallint NOT NULL,
    confidence smallint NOT NULL,
    report_type smallint NOT NULL,
    project_id integer NOT NULL,
    scanner_id bigint NOT NULL,
    primary_identifier_id bigint NOT NULL,
    project_fingerprint bytea NOT NULL,
    location_fingerprint bytea NOT NULL,
    uuid character varying(36) NOT NULL,
    name character varying NOT NULL,
    metadata_version character varying NOT NULL,
    raw_metadata text NOT NULL,
    vulnerability_id bigint
);

CREATE SEQUENCE public.vulnerability_occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_occurrences_id_seq OWNED BY public.vulnerability_occurrences.id;

CREATE TABLE public.vulnerability_scanners (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    external_id character varying NOT NULL,
    name character varying NOT NULL
);

CREATE SEQUENCE public.vulnerability_scanners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_scanners_id_seq OWNED BY public.vulnerability_scanners.id;

CREATE TABLE public.vulnerability_user_mentions (
    id bigint NOT NULL,
    vulnerability_id bigint NOT NULL,
    note_id integer,
    mentioned_users_ids integer[],
    mentioned_projects_ids integer[],
    mentioned_groups_ids integer[]
);

CREATE SEQUENCE public.vulnerability_user_mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.vulnerability_user_mentions_id_seq OWNED BY public.vulnerability_user_mentions.id;

CREATE TABLE public.web_hook_logs (
    id integer NOT NULL,
    web_hook_id integer NOT NULL,
    trigger character varying,
    url character varying,
    request_headers text,
    request_data text,
    response_headers text,
    response_body text,
    response_status character varying,
    execution_duration double precision,
    internal_error_message character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.web_hook_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.web_hook_logs_id_seq OWNED BY public.web_hook_logs.id;

CREATE TABLE public.web_hooks (
    id integer NOT NULL,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying DEFAULT 'ProjectHook'::character varying,
    service_id integer,
    push_events boolean DEFAULT true NOT NULL,
    issues_events boolean DEFAULT false NOT NULL,
    merge_requests_events boolean DEFAULT false NOT NULL,
    tag_push_events boolean DEFAULT false,
    group_id integer,
    note_events boolean DEFAULT false NOT NULL,
    enable_ssl_verification boolean DEFAULT true,
    wiki_page_events boolean DEFAULT false NOT NULL,
    pipeline_events boolean DEFAULT false NOT NULL,
    confidential_issues_events boolean DEFAULT false NOT NULL,
    repository_update_events boolean DEFAULT false NOT NULL,
    job_events boolean DEFAULT false NOT NULL,
    confidential_note_events boolean,
    push_events_branch_filter text,
    encrypted_token character varying,
    encrypted_token_iv character varying,
    encrypted_url character varying,
    encrypted_url_iv character varying
);

CREATE SEQUENCE public.web_hooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.web_hooks_id_seq OWNED BY public.web_hooks.id;

CREATE TABLE public.wiki_page_meta (
    id integer NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    title character varying(255) NOT NULL
);

CREATE SEQUENCE public.wiki_page_meta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.wiki_page_meta_id_seq OWNED BY public.wiki_page_meta.id;

CREATE TABLE public.wiki_page_slugs (
    id integer NOT NULL,
    canonical boolean DEFAULT false NOT NULL,
    wiki_page_meta_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    slug character varying(2048) NOT NULL
);

CREATE SEQUENCE public.wiki_page_slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.wiki_page_slugs_id_seq OWNED BY public.wiki_page_slugs.id;

CREATE TABLE public.x509_certificates (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    subject_key_identifier character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    serial_number bytea NOT NULL,
    certificate_status smallint DEFAULT 0 NOT NULL,
    x509_issuer_id bigint NOT NULL
);

CREATE SEQUENCE public.x509_certificates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.x509_certificates_id_seq OWNED BY public.x509_certificates.id;

CREATE TABLE public.x509_commit_signatures (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    project_id bigint NOT NULL,
    x509_certificate_id bigint NOT NULL,
    commit_sha bytea NOT NULL,
    verification_status smallint DEFAULT 0 NOT NULL
);

CREATE SEQUENCE public.x509_commit_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.x509_commit_signatures_id_seq OWNED BY public.x509_commit_signatures.id;

CREATE TABLE public.x509_issuers (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    subject_key_identifier character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    crl_url character varying(255) NOT NULL
);

CREATE SEQUENCE public.x509_issuers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.x509_issuers_id_seq OWNED BY public.x509_issuers.id;

CREATE TABLE public.zoom_meetings (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    issue_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    issue_status smallint DEFAULT 1 NOT NULL,
    url character varying(255)
);

CREATE SEQUENCE public.zoom_meetings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.zoom_meetings_id_seq OWNED BY public.zoom_meetings.id;

ALTER TABLE ONLY public.abuse_reports ALTER COLUMN id SET DEFAULT nextval('public.abuse_reports_id_seq'::regclass);

ALTER TABLE ONLY public.alert_management_alert_assignees ALTER COLUMN id SET DEFAULT nextval('public.alert_management_alert_assignees_id_seq'::regclass);

ALTER TABLE ONLY public.alert_management_alert_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.alert_management_alert_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.alert_management_alerts ALTER COLUMN id SET DEFAULT nextval('public.alert_management_alerts_id_seq'::regclass);

ALTER TABLE ONLY public.alerts_service_data ALTER COLUMN id SET DEFAULT nextval('public.alerts_service_data_id_seq'::regclass);

ALTER TABLE ONLY public.allowed_email_domains ALTER COLUMN id SET DEFAULT nextval('public.allowed_email_domains_id_seq'::regclass);

ALTER TABLE ONLY public.analytics_cycle_analytics_group_stages ALTER COLUMN id SET DEFAULT nextval('public.analytics_cycle_analytics_group_stages_id_seq'::regclass);

ALTER TABLE ONLY public.analytics_cycle_analytics_project_stages ALTER COLUMN id SET DEFAULT nextval('public.analytics_cycle_analytics_project_stages_id_seq'::regclass);

ALTER TABLE ONLY public.appearances ALTER COLUMN id SET DEFAULT nextval('public.appearances_id_seq'::regclass);

ALTER TABLE ONLY public.application_setting_terms ALTER COLUMN id SET DEFAULT nextval('public.application_setting_terms_id_seq'::regclass);

ALTER TABLE ONLY public.application_settings ALTER COLUMN id SET DEFAULT nextval('public.application_settings_id_seq'::regclass);

ALTER TABLE ONLY public.approval_merge_request_rule_sources ALTER COLUMN id SET DEFAULT nextval('public.approval_merge_request_rule_sources_id_seq'::regclass);

ALTER TABLE ONLY public.approval_merge_request_rules ALTER COLUMN id SET DEFAULT nextval('public.approval_merge_request_rules_id_seq'::regclass);

ALTER TABLE ONLY public.approval_merge_request_rules_approved_approvers ALTER COLUMN id SET DEFAULT nextval('public.approval_merge_request_rules_approved_approvers_id_seq'::regclass);

ALTER TABLE ONLY public.approval_merge_request_rules_groups ALTER COLUMN id SET DEFAULT nextval('public.approval_merge_request_rules_groups_id_seq'::regclass);

ALTER TABLE ONLY public.approval_merge_request_rules_users ALTER COLUMN id SET DEFAULT nextval('public.approval_merge_request_rules_users_id_seq'::regclass);

ALTER TABLE ONLY public.approval_project_rules ALTER COLUMN id SET DEFAULT nextval('public.approval_project_rules_id_seq'::regclass);

ALTER TABLE ONLY public.approval_project_rules_groups ALTER COLUMN id SET DEFAULT nextval('public.approval_project_rules_groups_id_seq'::regclass);

ALTER TABLE ONLY public.approval_project_rules_users ALTER COLUMN id SET DEFAULT nextval('public.approval_project_rules_users_id_seq'::regclass);

ALTER TABLE ONLY public.approvals ALTER COLUMN id SET DEFAULT nextval('public.approvals_id_seq'::regclass);

ALTER TABLE ONLY public.approver_groups ALTER COLUMN id SET DEFAULT nextval('public.approver_groups_id_seq'::regclass);

ALTER TABLE ONLY public.approvers ALTER COLUMN id SET DEFAULT nextval('public.approvers_id_seq'::regclass);

ALTER TABLE ONLY public.audit_events ALTER COLUMN id SET DEFAULT nextval('public.audit_events_id_seq'::regclass);

ALTER TABLE ONLY public.award_emoji ALTER COLUMN id SET DEFAULT nextval('public.award_emoji_id_seq'::regclass);

ALTER TABLE ONLY public.badges ALTER COLUMN id SET DEFAULT nextval('public.badges_id_seq'::regclass);

ALTER TABLE ONLY public.board_assignees ALTER COLUMN id SET DEFAULT nextval('public.board_assignees_id_seq'::regclass);

ALTER TABLE ONLY public.board_group_recent_visits ALTER COLUMN id SET DEFAULT nextval('public.board_group_recent_visits_id_seq'::regclass);

ALTER TABLE ONLY public.board_labels ALTER COLUMN id SET DEFAULT nextval('public.board_labels_id_seq'::regclass);

ALTER TABLE ONLY public.board_project_recent_visits ALTER COLUMN id SET DEFAULT nextval('public.board_project_recent_visits_id_seq'::regclass);

ALTER TABLE ONLY public.board_user_preferences ALTER COLUMN id SET DEFAULT nextval('public.board_user_preferences_id_seq'::regclass);

ALTER TABLE ONLY public.boards ALTER COLUMN id SET DEFAULT nextval('public.boards_id_seq'::regclass);

ALTER TABLE ONLY public.broadcast_messages ALTER COLUMN id SET DEFAULT nextval('public.broadcast_messages_id_seq'::regclass);

ALTER TABLE ONLY public.chat_names ALTER COLUMN id SET DEFAULT nextval('public.chat_names_id_seq'::regclass);

ALTER TABLE ONLY public.chat_teams ALTER COLUMN id SET DEFAULT nextval('public.chat_teams_id_seq'::regclass);

ALTER TABLE ONLY public.ci_build_needs ALTER COLUMN id SET DEFAULT nextval('public.ci_build_needs_id_seq'::regclass);

ALTER TABLE ONLY public.ci_build_report_results ALTER COLUMN build_id SET DEFAULT nextval('public.ci_build_report_results_build_id_seq'::regclass);

ALTER TABLE ONLY public.ci_build_trace_chunks ALTER COLUMN id SET DEFAULT nextval('public.ci_build_trace_chunks_id_seq'::regclass);

ALTER TABLE ONLY public.ci_build_trace_section_names ALTER COLUMN id SET DEFAULT nextval('public.ci_build_trace_section_names_id_seq'::regclass);

ALTER TABLE ONLY public.ci_builds ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_id_seq'::regclass);

ALTER TABLE ONLY public.ci_builds_metadata ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_metadata_id_seq'::regclass);

ALTER TABLE ONLY public.ci_builds_runner_session ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_runner_session_id_seq'::regclass);

ALTER TABLE ONLY public.ci_daily_build_group_report_results ALTER COLUMN id SET DEFAULT nextval('public.ci_daily_build_group_report_results_id_seq'::regclass);

ALTER TABLE ONLY public.ci_daily_report_results ALTER COLUMN id SET DEFAULT nextval('public.ci_daily_report_results_id_seq'::regclass);

ALTER TABLE ONLY public.ci_freeze_periods ALTER COLUMN id SET DEFAULT nextval('public.ci_freeze_periods_id_seq'::regclass);

ALTER TABLE ONLY public.ci_group_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_group_variables_id_seq'::regclass);

ALTER TABLE ONLY public.ci_instance_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_instance_variables_id_seq'::regclass);

ALTER TABLE ONLY public.ci_job_artifacts ALTER COLUMN id SET DEFAULT nextval('public.ci_job_artifacts_id_seq'::regclass);

ALTER TABLE ONLY public.ci_job_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_job_variables_id_seq'::regclass);

ALTER TABLE ONLY public.ci_pipeline_chat_data ALTER COLUMN id SET DEFAULT nextval('public.ci_pipeline_chat_data_id_seq'::regclass);

ALTER TABLE ONLY public.ci_pipeline_schedule_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_pipeline_schedule_variables_id_seq'::regclass);

ALTER TABLE ONLY public.ci_pipeline_schedules ALTER COLUMN id SET DEFAULT nextval('public.ci_pipeline_schedules_id_seq'::regclass);

ALTER TABLE ONLY public.ci_pipeline_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_pipeline_variables_id_seq'::regclass);

ALTER TABLE ONLY public.ci_pipelines ALTER COLUMN id SET DEFAULT nextval('public.ci_pipelines_id_seq'::regclass);

ALTER TABLE ONLY public.ci_pipelines_config ALTER COLUMN pipeline_id SET DEFAULT nextval('public.ci_pipelines_config_pipeline_id_seq'::regclass);

ALTER TABLE ONLY public.ci_refs ALTER COLUMN id SET DEFAULT nextval('public.ci_refs_id_seq'::regclass);

ALTER TABLE ONLY public.ci_resource_groups ALTER COLUMN id SET DEFAULT nextval('public.ci_resource_groups_id_seq'::regclass);

ALTER TABLE ONLY public.ci_resources ALTER COLUMN id SET DEFAULT nextval('public.ci_resources_id_seq'::regclass);

ALTER TABLE ONLY public.ci_runner_namespaces ALTER COLUMN id SET DEFAULT nextval('public.ci_runner_namespaces_id_seq'::regclass);

ALTER TABLE ONLY public.ci_runner_projects ALTER COLUMN id SET DEFAULT nextval('public.ci_runner_projects_id_seq'::regclass);

ALTER TABLE ONLY public.ci_runners ALTER COLUMN id SET DEFAULT nextval('public.ci_runners_id_seq'::regclass);

ALTER TABLE ONLY public.ci_sources_pipelines ALTER COLUMN id SET DEFAULT nextval('public.ci_sources_pipelines_id_seq'::regclass);

ALTER TABLE ONLY public.ci_sources_projects ALTER COLUMN id SET DEFAULT nextval('public.ci_sources_projects_id_seq'::regclass);

ALTER TABLE ONLY public.ci_stages ALTER COLUMN id SET DEFAULT nextval('public.ci_stages_id_seq'::regclass);

ALTER TABLE ONLY public.ci_subscriptions_projects ALTER COLUMN id SET DEFAULT nextval('public.ci_subscriptions_projects_id_seq'::regclass);

ALTER TABLE ONLY public.ci_trigger_requests ALTER COLUMN id SET DEFAULT nextval('public.ci_trigger_requests_id_seq'::regclass);

ALTER TABLE ONLY public.ci_triggers ALTER COLUMN id SET DEFAULT nextval('public.ci_triggers_id_seq'::regclass);

ALTER TABLE ONLY public.ci_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_variables_id_seq'::regclass);

ALTER TABLE ONLY public.cluster_groups ALTER COLUMN id SET DEFAULT nextval('public.cluster_groups_id_seq'::regclass);

ALTER TABLE ONLY public.cluster_platforms_kubernetes ALTER COLUMN id SET DEFAULT nextval('public.cluster_platforms_kubernetes_id_seq'::regclass);

ALTER TABLE ONLY public.cluster_projects ALTER COLUMN id SET DEFAULT nextval('public.cluster_projects_id_seq'::regclass);

ALTER TABLE ONLY public.cluster_providers_aws ALTER COLUMN id SET DEFAULT nextval('public.cluster_providers_aws_id_seq'::regclass);

ALTER TABLE ONLY public.cluster_providers_gcp ALTER COLUMN id SET DEFAULT nextval('public.cluster_providers_gcp_id_seq'::regclass);

ALTER TABLE ONLY public.clusters ALTER COLUMN id SET DEFAULT nextval('public.clusters_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_cert_managers ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_cert_managers_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_crossplane ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_crossplane_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_elastic_stacks ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_elastic_stacks_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_fluentd ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_fluentd_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_helm ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_helm_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_ingress ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_ingress_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_jupyter ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_jupyter_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_knative ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_knative_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_prometheus ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_prometheus_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_applications_runners ALTER COLUMN id SET DEFAULT nextval('public.clusters_applications_runners_id_seq'::regclass);

ALTER TABLE ONLY public.clusters_kubernetes_namespaces ALTER COLUMN id SET DEFAULT nextval('public.clusters_kubernetes_namespaces_id_seq'::regclass);

ALTER TABLE ONLY public.commit_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.commit_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.container_repositories ALTER COLUMN id SET DEFAULT nextval('public.container_repositories_id_seq'::regclass);

ALTER TABLE ONLY public.conversational_development_index_metrics ALTER COLUMN id SET DEFAULT nextval('public.conversational_development_index_metrics_id_seq'::regclass);

ALTER TABLE ONLY public.dependency_proxy_blobs ALTER COLUMN id SET DEFAULT nextval('public.dependency_proxy_blobs_id_seq'::regclass);

ALTER TABLE ONLY public.dependency_proxy_group_settings ALTER COLUMN id SET DEFAULT nextval('public.dependency_proxy_group_settings_id_seq'::regclass);

ALTER TABLE ONLY public.deploy_keys_projects ALTER COLUMN id SET DEFAULT nextval('public.deploy_keys_projects_id_seq'::regclass);

ALTER TABLE ONLY public.deploy_tokens ALTER COLUMN id SET DEFAULT nextval('public.deploy_tokens_id_seq'::regclass);

ALTER TABLE ONLY public.deployments ALTER COLUMN id SET DEFAULT nextval('public.deployments_id_seq'::regclass);

ALTER TABLE ONLY public.description_versions ALTER COLUMN id SET DEFAULT nextval('public.description_versions_id_seq'::regclass);

ALTER TABLE ONLY public.design_management_designs ALTER COLUMN id SET DEFAULT nextval('public.design_management_designs_id_seq'::regclass);

ALTER TABLE ONLY public.design_management_designs_versions ALTER COLUMN id SET DEFAULT nextval('public.design_management_designs_versions_id_seq'::regclass);

ALTER TABLE ONLY public.design_management_versions ALTER COLUMN id SET DEFAULT nextval('public.design_management_versions_id_seq'::regclass);

ALTER TABLE ONLY public.design_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.design_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.diff_note_positions ALTER COLUMN id SET DEFAULT nextval('public.diff_note_positions_id_seq'::regclass);

ALTER TABLE ONLY public.draft_notes ALTER COLUMN id SET DEFAULT nextval('public.draft_notes_id_seq'::regclass);

ALTER TABLE ONLY public.emails ALTER COLUMN id SET DEFAULT nextval('public.emails_id_seq'::regclass);

ALTER TABLE ONLY public.environments ALTER COLUMN id SET DEFAULT nextval('public.environments_id_seq'::regclass);

ALTER TABLE ONLY public.epic_issues ALTER COLUMN id SET DEFAULT nextval('public.epic_issues_id_seq'::regclass);

ALTER TABLE ONLY public.epic_metrics ALTER COLUMN id SET DEFAULT nextval('public.epic_metrics_id_seq'::regclass);

ALTER TABLE ONLY public.epic_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.epic_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.epics ALTER COLUMN id SET DEFAULT nextval('public.epics_id_seq'::regclass);

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);

ALTER TABLE ONLY public.evidences ALTER COLUMN id SET DEFAULT nextval('public.evidences_id_seq'::regclass);

ALTER TABLE ONLY public.external_pull_requests ALTER COLUMN id SET DEFAULT nextval('public.external_pull_requests_id_seq'::regclass);

ALTER TABLE ONLY public.feature_gates ALTER COLUMN id SET DEFAULT nextval('public.feature_gates_id_seq'::regclass);

ALTER TABLE ONLY public.features ALTER COLUMN id SET DEFAULT nextval('public.features_id_seq'::regclass);

ALTER TABLE ONLY public.fork_network_members ALTER COLUMN id SET DEFAULT nextval('public.fork_network_members_id_seq'::regclass);

ALTER TABLE ONLY public.fork_networks ALTER COLUMN id SET DEFAULT nextval('public.fork_networks_id_seq'::regclass);

ALTER TABLE ONLY public.geo_cache_invalidation_events ALTER COLUMN id SET DEFAULT nextval('public.geo_cache_invalidation_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_container_repository_updated_events ALTER COLUMN id SET DEFAULT nextval('public.geo_container_repository_updated_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_event_log ALTER COLUMN id SET DEFAULT nextval('public.geo_event_log_id_seq'::regclass);

ALTER TABLE ONLY public.geo_events ALTER COLUMN id SET DEFAULT nextval('public.geo_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_hashed_storage_attachments_events ALTER COLUMN id SET DEFAULT nextval('public.geo_hashed_storage_attachments_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_hashed_storage_migrated_events ALTER COLUMN id SET DEFAULT nextval('public.geo_hashed_storage_migrated_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_job_artifact_deleted_events ALTER COLUMN id SET DEFAULT nextval('public.geo_job_artifact_deleted_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_lfs_object_deleted_events ALTER COLUMN id SET DEFAULT nextval('public.geo_lfs_object_deleted_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_node_namespace_links ALTER COLUMN id SET DEFAULT nextval('public.geo_node_namespace_links_id_seq'::regclass);

ALTER TABLE ONLY public.geo_node_statuses ALTER COLUMN id SET DEFAULT nextval('public.geo_node_statuses_id_seq'::regclass);

ALTER TABLE ONLY public.geo_nodes ALTER COLUMN id SET DEFAULT nextval('public.geo_nodes_id_seq'::regclass);

ALTER TABLE ONLY public.geo_repositories_changed_events ALTER COLUMN id SET DEFAULT nextval('public.geo_repositories_changed_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_repository_created_events ALTER COLUMN id SET DEFAULT nextval('public.geo_repository_created_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_repository_deleted_events ALTER COLUMN id SET DEFAULT nextval('public.geo_repository_deleted_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_repository_renamed_events ALTER COLUMN id SET DEFAULT nextval('public.geo_repository_renamed_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_repository_updated_events ALTER COLUMN id SET DEFAULT nextval('public.geo_repository_updated_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_reset_checksum_events ALTER COLUMN id SET DEFAULT nextval('public.geo_reset_checksum_events_id_seq'::regclass);

ALTER TABLE ONLY public.geo_upload_deleted_events ALTER COLUMN id SET DEFAULT nextval('public.geo_upload_deleted_events_id_seq'::regclass);

ALTER TABLE ONLY public.gitlab_subscription_histories ALTER COLUMN id SET DEFAULT nextval('public.gitlab_subscription_histories_id_seq'::regclass);

ALTER TABLE ONLY public.gitlab_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.gitlab_subscriptions_id_seq'::regclass);

ALTER TABLE ONLY public.gpg_key_subkeys ALTER COLUMN id SET DEFAULT nextval('public.gpg_key_subkeys_id_seq'::regclass);

ALTER TABLE ONLY public.gpg_keys ALTER COLUMN id SET DEFAULT nextval('public.gpg_keys_id_seq'::regclass);

ALTER TABLE ONLY public.gpg_signatures ALTER COLUMN id SET DEFAULT nextval('public.gpg_signatures_id_seq'::regclass);

ALTER TABLE ONLY public.grafana_integrations ALTER COLUMN id SET DEFAULT nextval('public.grafana_integrations_id_seq'::regclass);

ALTER TABLE ONLY public.group_custom_attributes ALTER COLUMN id SET DEFAULT nextval('public.group_custom_attributes_id_seq'::regclass);

ALTER TABLE ONLY public.group_deploy_keys ALTER COLUMN id SET DEFAULT nextval('public.group_deploy_keys_id_seq'::regclass);

ALTER TABLE ONLY public.group_deploy_tokens ALTER COLUMN id SET DEFAULT nextval('public.group_deploy_tokens_id_seq'::regclass);

ALTER TABLE ONLY public.group_group_links ALTER COLUMN id SET DEFAULT nextval('public.group_group_links_id_seq'::regclass);

ALTER TABLE ONLY public.group_import_states ALTER COLUMN group_id SET DEFAULT nextval('public.group_import_states_group_id_seq'::regclass);

ALTER TABLE ONLY public.historical_data ALTER COLUMN id SET DEFAULT nextval('public.historical_data_id_seq'::regclass);

ALTER TABLE ONLY public.identities ALTER COLUMN id SET DEFAULT nextval('public.identities_id_seq'::regclass);

ALTER TABLE ONLY public.import_export_uploads ALTER COLUMN id SET DEFAULT nextval('public.import_export_uploads_id_seq'::regclass);

ALTER TABLE ONLY public.import_failures ALTER COLUMN id SET DEFAULT nextval('public.import_failures_id_seq'::regclass);

ALTER TABLE ONLY public.index_statuses ALTER COLUMN id SET DEFAULT nextval('public.index_statuses_id_seq'::regclass);

ALTER TABLE ONLY public.insights ALTER COLUMN id SET DEFAULT nextval('public.insights_id_seq'::regclass);

ALTER TABLE ONLY public.internal_ids ALTER COLUMN id SET DEFAULT nextval('public.internal_ids_id_seq'::regclass);

ALTER TABLE ONLY public.ip_restrictions ALTER COLUMN id SET DEFAULT nextval('public.ip_restrictions_id_seq'::regclass);

ALTER TABLE ONLY public.issue_links ALTER COLUMN id SET DEFAULT nextval('public.issue_links_id_seq'::regclass);

ALTER TABLE ONLY public.issue_metrics ALTER COLUMN id SET DEFAULT nextval('public.issue_metrics_id_seq'::regclass);

ALTER TABLE ONLY public.issue_tracker_data ALTER COLUMN id SET DEFAULT nextval('public.issue_tracker_data_id_seq'::regclass);

ALTER TABLE ONLY public.issue_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.issue_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);

ALTER TABLE ONLY public.jira_connect_installations ALTER COLUMN id SET DEFAULT nextval('public.jira_connect_installations_id_seq'::regclass);

ALTER TABLE ONLY public.jira_connect_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.jira_connect_subscriptions_id_seq'::regclass);

ALTER TABLE ONLY public.jira_imports ALTER COLUMN id SET DEFAULT nextval('public.jira_imports_id_seq'::regclass);

ALTER TABLE ONLY public.jira_tracker_data ALTER COLUMN id SET DEFAULT nextval('public.jira_tracker_data_id_seq'::regclass);

ALTER TABLE ONLY public.keys ALTER COLUMN id SET DEFAULT nextval('public.keys_id_seq'::regclass);

ALTER TABLE ONLY public.label_links ALTER COLUMN id SET DEFAULT nextval('public.label_links_id_seq'::regclass);

ALTER TABLE ONLY public.label_priorities ALTER COLUMN id SET DEFAULT nextval('public.label_priorities_id_seq'::regclass);

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);

ALTER TABLE ONLY public.ldap_group_links ALTER COLUMN id SET DEFAULT nextval('public.ldap_group_links_id_seq'::regclass);

ALTER TABLE ONLY public.lfs_file_locks ALTER COLUMN id SET DEFAULT nextval('public.lfs_file_locks_id_seq'::regclass);

ALTER TABLE ONLY public.lfs_objects ALTER COLUMN id SET DEFAULT nextval('public.lfs_objects_id_seq'::regclass);

ALTER TABLE ONLY public.lfs_objects_projects ALTER COLUMN id SET DEFAULT nextval('public.lfs_objects_projects_id_seq'::regclass);

ALTER TABLE ONLY public.licenses ALTER COLUMN id SET DEFAULT nextval('public.licenses_id_seq'::regclass);

ALTER TABLE ONLY public.list_user_preferences ALTER COLUMN id SET DEFAULT nextval('public.list_user_preferences_id_seq'::regclass);

ALTER TABLE ONLY public.lists ALTER COLUMN id SET DEFAULT nextval('public.lists_id_seq'::regclass);

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);

ALTER TABLE ONLY public.merge_request_assignees ALTER COLUMN id SET DEFAULT nextval('public.merge_request_assignees_id_seq'::regclass);

ALTER TABLE ONLY public.merge_request_blocks ALTER COLUMN id SET DEFAULT nextval('public.merge_request_blocks_id_seq'::regclass);

ALTER TABLE ONLY public.merge_request_context_commits ALTER COLUMN id SET DEFAULT nextval('public.merge_request_context_commits_id_seq'::regclass);

ALTER TABLE ONLY public.merge_request_diffs ALTER COLUMN id SET DEFAULT nextval('public.merge_request_diffs_id_seq'::regclass);

ALTER TABLE ONLY public.merge_request_metrics ALTER COLUMN id SET DEFAULT nextval('public.merge_request_metrics_id_seq'::regclass);

ALTER TABLE ONLY public.merge_request_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.merge_request_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.merge_requests ALTER COLUMN id SET DEFAULT nextval('public.merge_requests_id_seq'::regclass);

ALTER TABLE ONLY public.merge_requests_closing_issues ALTER COLUMN id SET DEFAULT nextval('public.merge_requests_closing_issues_id_seq'::regclass);

ALTER TABLE ONLY public.merge_trains ALTER COLUMN id SET DEFAULT nextval('public.merge_trains_id_seq'::regclass);

ALTER TABLE ONLY public.metrics_dashboard_annotations ALTER COLUMN id SET DEFAULT nextval('public.metrics_dashboard_annotations_id_seq'::regclass);

ALTER TABLE ONLY public.metrics_users_starred_dashboards ALTER COLUMN id SET DEFAULT nextval('public.metrics_users_starred_dashboards_id_seq'::regclass);

ALTER TABLE ONLY public.milestones ALTER COLUMN id SET DEFAULT nextval('public.milestones_id_seq'::regclass);

ALTER TABLE ONLY public.namespace_statistics ALTER COLUMN id SET DEFAULT nextval('public.namespace_statistics_id_seq'::regclass);

ALTER TABLE ONLY public.namespaces ALTER COLUMN id SET DEFAULT nextval('public.namespaces_id_seq'::regclass);

ALTER TABLE ONLY public.note_diff_files ALTER COLUMN id SET DEFAULT nextval('public.note_diff_files_id_seq'::regclass);

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);

ALTER TABLE ONLY public.notification_settings ALTER COLUMN id SET DEFAULT nextval('public.notification_settings_id_seq'::regclass);

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);

ALTER TABLE ONLY public.oauth_openid_requests ALTER COLUMN id SET DEFAULT nextval('public.oauth_openid_requests_id_seq'::regclass);

ALTER TABLE ONLY public.open_project_tracker_data ALTER COLUMN id SET DEFAULT nextval('public.open_project_tracker_data_id_seq'::regclass);

ALTER TABLE ONLY public.operations_feature_flag_scopes ALTER COLUMN id SET DEFAULT nextval('public.operations_feature_flag_scopes_id_seq'::regclass);

ALTER TABLE ONLY public.operations_feature_flags ALTER COLUMN id SET DEFAULT nextval('public.operations_feature_flags_id_seq'::regclass);

ALTER TABLE ONLY public.operations_feature_flags_clients ALTER COLUMN id SET DEFAULT nextval('public.operations_feature_flags_clients_id_seq'::regclass);

ALTER TABLE ONLY public.operations_feature_flags_issues ALTER COLUMN id SET DEFAULT nextval('public.operations_feature_flags_issues_id_seq'::regclass);

ALTER TABLE ONLY public.operations_scopes ALTER COLUMN id SET DEFAULT nextval('public.operations_scopes_id_seq'::regclass);

ALTER TABLE ONLY public.operations_strategies ALTER COLUMN id SET DEFAULT nextval('public.operations_strategies_id_seq'::regclass);

ALTER TABLE ONLY public.operations_strategies_user_lists ALTER COLUMN id SET DEFAULT nextval('public.operations_strategies_user_lists_id_seq'::regclass);

ALTER TABLE ONLY public.operations_user_lists ALTER COLUMN id SET DEFAULT nextval('public.operations_user_lists_id_seq'::regclass);

ALTER TABLE ONLY public.packages_build_infos ALTER COLUMN id SET DEFAULT nextval('public.packages_build_infos_id_seq'::regclass);

ALTER TABLE ONLY public.packages_conan_file_metadata ALTER COLUMN id SET DEFAULT nextval('public.packages_conan_file_metadata_id_seq'::regclass);

ALTER TABLE ONLY public.packages_conan_metadata ALTER COLUMN id SET DEFAULT nextval('public.packages_conan_metadata_id_seq'::regclass);

ALTER TABLE ONLY public.packages_dependencies ALTER COLUMN id SET DEFAULT nextval('public.packages_dependencies_id_seq'::regclass);

ALTER TABLE ONLY public.packages_dependency_links ALTER COLUMN id SET DEFAULT nextval('public.packages_dependency_links_id_seq'::regclass);

ALTER TABLE ONLY public.packages_maven_metadata ALTER COLUMN id SET DEFAULT nextval('public.packages_maven_metadata_id_seq'::regclass);

ALTER TABLE ONLY public.packages_package_files ALTER COLUMN id SET DEFAULT nextval('public.packages_package_files_id_seq'::regclass);

ALTER TABLE ONLY public.packages_packages ALTER COLUMN id SET DEFAULT nextval('public.packages_packages_id_seq'::regclass);

ALTER TABLE ONLY public.packages_tags ALTER COLUMN id SET DEFAULT nextval('public.packages_tags_id_seq'::regclass);

ALTER TABLE ONLY public.pages_domain_acme_orders ALTER COLUMN id SET DEFAULT nextval('public.pages_domain_acme_orders_id_seq'::regclass);

ALTER TABLE ONLY public.pages_domains ALTER COLUMN id SET DEFAULT nextval('public.pages_domains_id_seq'::regclass);

ALTER TABLE ONLY public.partitioned_foreign_keys ALTER COLUMN id SET DEFAULT nextval('public.partitioned_foreign_keys_id_seq'::regclass);

ALTER TABLE ONLY public.path_locks ALTER COLUMN id SET DEFAULT nextval('public.path_locks_id_seq'::regclass);

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);

ALTER TABLE ONLY public.plan_limits ALTER COLUMN id SET DEFAULT nextval('public.plan_limits_id_seq'::regclass);

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);

ALTER TABLE ONLY public.pool_repositories ALTER COLUMN id SET DEFAULT nextval('public.pool_repositories_id_seq'::regclass);

ALTER TABLE ONLY public.programming_languages ALTER COLUMN id SET DEFAULT nextval('public.programming_languages_id_seq'::regclass);

ALTER TABLE ONLY public.project_aliases ALTER COLUMN id SET DEFAULT nextval('public.project_aliases_id_seq'::regclass);

ALTER TABLE ONLY public.project_auto_devops ALTER COLUMN id SET DEFAULT nextval('public.project_auto_devops_id_seq'::regclass);

ALTER TABLE ONLY public.project_ci_cd_settings ALTER COLUMN id SET DEFAULT nextval('public.project_ci_cd_settings_id_seq'::regclass);

ALTER TABLE ONLY public.project_compliance_framework_settings ALTER COLUMN project_id SET DEFAULT nextval('public.project_compliance_framework_settings_project_id_seq'::regclass);

ALTER TABLE ONLY public.project_custom_attributes ALTER COLUMN id SET DEFAULT nextval('public.project_custom_attributes_id_seq'::regclass);

ALTER TABLE ONLY public.project_daily_statistics ALTER COLUMN id SET DEFAULT nextval('public.project_daily_statistics_id_seq'::regclass);

ALTER TABLE ONLY public.project_deploy_tokens ALTER COLUMN id SET DEFAULT nextval('public.project_deploy_tokens_id_seq'::regclass);

ALTER TABLE ONLY public.project_export_jobs ALTER COLUMN id SET DEFAULT nextval('public.project_export_jobs_id_seq'::regclass);

ALTER TABLE ONLY public.project_features ALTER COLUMN id SET DEFAULT nextval('public.project_features_id_seq'::regclass);

ALTER TABLE ONLY public.project_group_links ALTER COLUMN id SET DEFAULT nextval('public.project_group_links_id_seq'::regclass);

ALTER TABLE ONLY public.project_import_data ALTER COLUMN id SET DEFAULT nextval('public.project_import_data_id_seq'::regclass);

ALTER TABLE ONLY public.project_incident_management_settings ALTER COLUMN project_id SET DEFAULT nextval('public.project_incident_management_settings_project_id_seq'::regclass);

ALTER TABLE ONLY public.project_mirror_data ALTER COLUMN id SET DEFAULT nextval('public.project_mirror_data_id_seq'::regclass);

ALTER TABLE ONLY public.project_repositories ALTER COLUMN id SET DEFAULT nextval('public.project_repositories_id_seq'::regclass);

ALTER TABLE ONLY public.project_repository_states ALTER COLUMN id SET DEFAULT nextval('public.project_repository_states_id_seq'::regclass);

ALTER TABLE ONLY public.project_repository_storage_moves ALTER COLUMN id SET DEFAULT nextval('public.project_repository_storage_moves_id_seq'::regclass);

ALTER TABLE ONLY public.project_security_settings ALTER COLUMN project_id SET DEFAULT nextval('public.project_security_settings_project_id_seq'::regclass);

ALTER TABLE ONLY public.project_statistics ALTER COLUMN id SET DEFAULT nextval('public.project_statistics_id_seq'::regclass);

ALTER TABLE ONLY public.project_tracing_settings ALTER COLUMN id SET DEFAULT nextval('public.project_tracing_settings_id_seq'::regclass);

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);

ALTER TABLE ONLY public.prometheus_alert_events ALTER COLUMN id SET DEFAULT nextval('public.prometheus_alert_events_id_seq'::regclass);

ALTER TABLE ONLY public.prometheus_alerts ALTER COLUMN id SET DEFAULT nextval('public.prometheus_alerts_id_seq'::regclass);

ALTER TABLE ONLY public.prometheus_metrics ALTER COLUMN id SET DEFAULT nextval('public.prometheus_metrics_id_seq'::regclass);

ALTER TABLE ONLY public.protected_branch_merge_access_levels ALTER COLUMN id SET DEFAULT nextval('public.protected_branch_merge_access_levels_id_seq'::regclass);

ALTER TABLE ONLY public.protected_branch_push_access_levels ALTER COLUMN id SET DEFAULT nextval('public.protected_branch_push_access_levels_id_seq'::regclass);

ALTER TABLE ONLY public.protected_branch_unprotect_access_levels ALTER COLUMN id SET DEFAULT nextval('public.protected_branch_unprotect_access_levels_id_seq'::regclass);

ALTER TABLE ONLY public.protected_branches ALTER COLUMN id SET DEFAULT nextval('public.protected_branches_id_seq'::regclass);

ALTER TABLE ONLY public.protected_environment_deploy_access_levels ALTER COLUMN id SET DEFAULT nextval('public.protected_environment_deploy_access_levels_id_seq'::regclass);

ALTER TABLE ONLY public.protected_environments ALTER COLUMN id SET DEFAULT nextval('public.protected_environments_id_seq'::regclass);

ALTER TABLE ONLY public.protected_tag_create_access_levels ALTER COLUMN id SET DEFAULT nextval('public.protected_tag_create_access_levels_id_seq'::regclass);

ALTER TABLE ONLY public.protected_tags ALTER COLUMN id SET DEFAULT nextval('public.protected_tags_id_seq'::regclass);

ALTER TABLE ONLY public.push_rules ALTER COLUMN id SET DEFAULT nextval('public.push_rules_id_seq'::regclass);

ALTER TABLE ONLY public.redirect_routes ALTER COLUMN id SET DEFAULT nextval('public.redirect_routes_id_seq'::regclass);

ALTER TABLE ONLY public.release_links ALTER COLUMN id SET DEFAULT nextval('public.release_links_id_seq'::regclass);

ALTER TABLE ONLY public.releases ALTER COLUMN id SET DEFAULT nextval('public.releases_id_seq'::regclass);

ALTER TABLE ONLY public.remote_mirrors ALTER COLUMN id SET DEFAULT nextval('public.remote_mirrors_id_seq'::regclass);

ALTER TABLE ONLY public.requirements ALTER COLUMN id SET DEFAULT nextval('public.requirements_id_seq'::regclass);

ALTER TABLE ONLY public.requirements_management_test_reports ALTER COLUMN id SET DEFAULT nextval('public.requirements_management_test_reports_id_seq'::regclass);

ALTER TABLE ONLY public.resource_label_events ALTER COLUMN id SET DEFAULT nextval('public.resource_label_events_id_seq'::regclass);

ALTER TABLE ONLY public.resource_milestone_events ALTER COLUMN id SET DEFAULT nextval('public.resource_milestone_events_id_seq'::regclass);

ALTER TABLE ONLY public.resource_state_events ALTER COLUMN id SET DEFAULT nextval('public.resource_state_events_id_seq'::regclass);

ALTER TABLE ONLY public.resource_weight_events ALTER COLUMN id SET DEFAULT nextval('public.resource_weight_events_id_seq'::regclass);

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);

ALTER TABLE ONLY public.routes ALTER COLUMN id SET DEFAULT nextval('public.routes_id_seq'::regclass);

ALTER TABLE ONLY public.saml_providers ALTER COLUMN id SET DEFAULT nextval('public.saml_providers_id_seq'::regclass);

ALTER TABLE ONLY public.scim_identities ALTER COLUMN id SET DEFAULT nextval('public.scim_identities_id_seq'::regclass);

ALTER TABLE ONLY public.scim_oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.scim_oauth_access_tokens_id_seq'::regclass);

ALTER TABLE ONLY public.security_scans ALTER COLUMN id SET DEFAULT nextval('public.security_scans_id_seq'::regclass);

ALTER TABLE ONLY public.self_managed_prometheus_alert_events ALTER COLUMN id SET DEFAULT nextval('public.self_managed_prometheus_alert_events_id_seq'::regclass);

ALTER TABLE ONLY public.sent_notifications ALTER COLUMN id SET DEFAULT nextval('public.sent_notifications_id_seq'::regclass);

ALTER TABLE ONLY public.sentry_issues ALTER COLUMN id SET DEFAULT nextval('public.sentry_issues_id_seq'::regclass);

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);

ALTER TABLE ONLY public.shards ALTER COLUMN id SET DEFAULT nextval('public.shards_id_seq'::regclass);

ALTER TABLE ONLY public.slack_integrations ALTER COLUMN id SET DEFAULT nextval('public.slack_integrations_id_seq'::regclass);

ALTER TABLE ONLY public.smartcard_identities ALTER COLUMN id SET DEFAULT nextval('public.smartcard_identities_id_seq'::regclass);

ALTER TABLE ONLY public.snippet_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.snippet_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.snippets ALTER COLUMN id SET DEFAULT nextval('public.snippets_id_seq'::regclass);

ALTER TABLE ONLY public.software_license_policies ALTER COLUMN id SET DEFAULT nextval('public.software_license_policies_id_seq'::regclass);

ALTER TABLE ONLY public.software_licenses ALTER COLUMN id SET DEFAULT nextval('public.software_licenses_id_seq'::regclass);

ALTER TABLE ONLY public.spam_logs ALTER COLUMN id SET DEFAULT nextval('public.spam_logs_id_seq'::regclass);

ALTER TABLE ONLY public.sprints ALTER COLUMN id SET DEFAULT nextval('public.sprints_id_seq'::regclass);

ALTER TABLE ONLY public.status_page_published_incidents ALTER COLUMN id SET DEFAULT nextval('public.status_page_published_incidents_id_seq'::regclass);

ALTER TABLE ONLY public.status_page_settings ALTER COLUMN project_id SET DEFAULT nextval('public.status_page_settings_project_id_seq'::regclass);

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);

ALTER TABLE ONLY public.suggestions ALTER COLUMN id SET DEFAULT nextval('public.suggestions_id_seq'::regclass);

ALTER TABLE ONLY public.system_note_metadata ALTER COLUMN id SET DEFAULT nextval('public.system_note_metadata_id_seq'::regclass);

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);

ALTER TABLE ONLY public.term_agreements ALTER COLUMN id SET DEFAULT nextval('public.term_agreements_id_seq'::regclass);

ALTER TABLE ONLY public.terraform_states ALTER COLUMN id SET DEFAULT nextval('public.terraform_states_id_seq'::regclass);

ALTER TABLE ONLY public.timelogs ALTER COLUMN id SET DEFAULT nextval('public.timelogs_id_seq'::regclass);

ALTER TABLE ONLY public.todos ALTER COLUMN id SET DEFAULT nextval('public.todos_id_seq'::regclass);

ALTER TABLE ONLY public.trending_projects ALTER COLUMN id SET DEFAULT nextval('public.trending_projects_id_seq'::regclass);

ALTER TABLE ONLY public.u2f_registrations ALTER COLUMN id SET DEFAULT nextval('public.u2f_registrations_id_seq'::regclass);

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);

ALTER TABLE ONLY public.user_agent_details ALTER COLUMN id SET DEFAULT nextval('public.user_agent_details_id_seq'::regclass);

ALTER TABLE ONLY public.user_callouts ALTER COLUMN id SET DEFAULT nextval('public.user_callouts_id_seq'::regclass);

ALTER TABLE ONLY public.user_canonical_emails ALTER COLUMN id SET DEFAULT nextval('public.user_canonical_emails_id_seq'::regclass);

ALTER TABLE ONLY public.user_custom_attributes ALTER COLUMN id SET DEFAULT nextval('public.user_custom_attributes_id_seq'::regclass);

ALTER TABLE ONLY public.user_details ALTER COLUMN user_id SET DEFAULT nextval('public.user_details_user_id_seq'::regclass);

ALTER TABLE ONLY public.user_preferences ALTER COLUMN id SET DEFAULT nextval('public.user_preferences_id_seq'::regclass);

ALTER TABLE ONLY public.user_statuses ALTER COLUMN user_id SET DEFAULT nextval('public.user_statuses_user_id_seq'::regclass);

ALTER TABLE ONLY public.user_synced_attributes_metadata ALTER COLUMN id SET DEFAULT nextval('public.user_synced_attributes_metadata_id_seq'::regclass);

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);

ALTER TABLE ONLY public.users_ops_dashboard_projects ALTER COLUMN id SET DEFAULT nextval('public.users_ops_dashboard_projects_id_seq'::regclass);

ALTER TABLE ONLY public.users_star_projects ALTER COLUMN id SET DEFAULT nextval('public.users_star_projects_id_seq'::regclass);

ALTER TABLE ONLY public.users_statistics ALTER COLUMN id SET DEFAULT nextval('public.users_statistics_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerabilities ALTER COLUMN id SET DEFAULT nextval('public.vulnerabilities_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_exports ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_exports_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_feedback ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_feedback_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_identifiers ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_identifiers_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_issue_links ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_issue_links_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_occurrence_identifiers ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_occurrence_identifiers_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_occurrence_pipelines ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_occurrence_pipelines_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_occurrences ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_occurrences_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_scanners ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_scanners_id_seq'::regclass);

ALTER TABLE ONLY public.vulnerability_user_mentions ALTER COLUMN id SET DEFAULT nextval('public.vulnerability_user_mentions_id_seq'::regclass);

ALTER TABLE ONLY public.web_hook_logs ALTER COLUMN id SET DEFAULT nextval('public.web_hook_logs_id_seq'::regclass);

ALTER TABLE ONLY public.web_hooks ALTER COLUMN id SET DEFAULT nextval('public.web_hooks_id_seq'::regclass);

ALTER TABLE ONLY public.wiki_page_meta ALTER COLUMN id SET DEFAULT nextval('public.wiki_page_meta_id_seq'::regclass);

ALTER TABLE ONLY public.wiki_page_slugs ALTER COLUMN id SET DEFAULT nextval('public.wiki_page_slugs_id_seq'::regclass);

ALTER TABLE ONLY public.x509_certificates ALTER COLUMN id SET DEFAULT nextval('public.x509_certificates_id_seq'::regclass);

ALTER TABLE ONLY public.x509_commit_signatures ALTER COLUMN id SET DEFAULT nextval('public.x509_commit_signatures_id_seq'::regclass);

ALTER TABLE ONLY public.x509_issuers ALTER COLUMN id SET DEFAULT nextval('public.x509_issuers_id_seq'::regclass);

ALTER TABLE ONLY public.zoom_meetings ALTER COLUMN id SET DEFAULT nextval('public.zoom_meetings_id_seq'::regclass);

ALTER TABLE ONLY public.abuse_reports
    ADD CONSTRAINT abuse_reports_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.alert_management_alert_assignees
    ADD CONSTRAINT alert_management_alert_assignees_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.alert_management_alert_user_mentions
    ADD CONSTRAINT alert_management_alert_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.alert_management_alerts
    ADD CONSTRAINT alert_management_alerts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.alerts_service_data
    ADD CONSTRAINT alerts_service_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.allowed_email_domains
    ADD CONSTRAINT allowed_email_domains_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.analytics_cycle_analytics_group_stages
    ADD CONSTRAINT analytics_cycle_analytics_group_stages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.analytics_cycle_analytics_project_stages
    ADD CONSTRAINT analytics_cycle_analytics_project_stages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.appearances
    ADD CONSTRAINT appearances_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.application_setting_terms
    ADD CONSTRAINT application_setting_terms_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT application_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_merge_request_rule_sources
    ADD CONSTRAINT approval_merge_request_rule_sources_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_merge_request_rules_approved_approvers
    ADD CONSTRAINT approval_merge_request_rules_approved_approvers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_merge_request_rules_groups
    ADD CONSTRAINT approval_merge_request_rules_groups_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_merge_request_rules
    ADD CONSTRAINT approval_merge_request_rules_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_merge_request_rules_users
    ADD CONSTRAINT approval_merge_request_rules_users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_project_rules_groups
    ADD CONSTRAINT approval_project_rules_groups_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_project_rules
    ADD CONSTRAINT approval_project_rules_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approval_project_rules_users
    ADD CONSTRAINT approval_project_rules_users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approver_groups
    ADD CONSTRAINT approver_groups_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.approvers
    ADD CONSTRAINT approvers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.award_emoji
    ADD CONSTRAINT award_emoji_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.aws_roles
    ADD CONSTRAINT aws_roles_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.board_assignees
    ADD CONSTRAINT board_assignees_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.board_group_recent_visits
    ADD CONSTRAINT board_group_recent_visits_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.board_labels
    ADD CONSTRAINT board_labels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.board_project_recent_visits
    ADD CONSTRAINT board_project_recent_visits_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.board_user_preferences
    ADD CONSTRAINT board_user_preferences_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.broadcast_messages
    ADD CONSTRAINT broadcast_messages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.chat_names
    ADD CONSTRAINT chat_names_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.chat_teams
    ADD CONSTRAINT chat_teams_pkey PRIMARY KEY (id);

ALTER TABLE public.design_management_designs
    ADD CONSTRAINT check_07155e2715 CHECK ((char_length((filename)::text) <= 255)) NOT VALID;

ALTER TABLE public.ci_job_artifacts
    ADD CONSTRAINT check_27f0f6dbab CHECK ((file_store IS NOT NULL)) NOT VALID;

ALTER TABLE public.uploads
    ADD CONSTRAINT check_5e9547379c CHECK ((store IS NOT NULL)) NOT VALID;

ALTER TABLE public.lfs_objects
    ADD CONSTRAINT check_eecfc5717d CHECK ((file_store IS NOT NULL)) NOT VALID;

ALTER TABLE ONLY public.ci_build_needs
    ADD CONSTRAINT ci_build_needs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_build_report_results
    ADD CONSTRAINT ci_build_report_results_pkey PRIMARY KEY (build_id);

ALTER TABLE ONLY public.ci_build_trace_chunks
    ADD CONSTRAINT ci_build_trace_chunks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_build_trace_section_names
    ADD CONSTRAINT ci_build_trace_section_names_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_builds_metadata
    ADD CONSTRAINT ci_builds_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT ci_builds_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_builds_runner_session
    ADD CONSTRAINT ci_builds_runner_session_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_daily_build_group_report_results
    ADD CONSTRAINT ci_daily_build_group_report_results_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_daily_report_results
    ADD CONSTRAINT ci_daily_report_results_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_freeze_periods
    ADD CONSTRAINT ci_freeze_periods_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_group_variables
    ADD CONSTRAINT ci_group_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_instance_variables
    ADD CONSTRAINT ci_instance_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_job_artifacts
    ADD CONSTRAINT ci_job_artifacts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_job_variables
    ADD CONSTRAINT ci_job_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_pipeline_chat_data
    ADD CONSTRAINT ci_pipeline_chat_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_pipeline_schedule_variables
    ADD CONSTRAINT ci_pipeline_schedule_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_pipeline_schedules
    ADD CONSTRAINT ci_pipeline_schedules_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_pipeline_variables
    ADD CONSTRAINT ci_pipeline_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_pipelines_config
    ADD CONSTRAINT ci_pipelines_config_pkey PRIMARY KEY (pipeline_id);

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT ci_pipelines_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_refs
    ADD CONSTRAINT ci_refs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_resource_groups
    ADD CONSTRAINT ci_resource_groups_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_resources
    ADD CONSTRAINT ci_resources_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_runner_namespaces
    ADD CONSTRAINT ci_runner_namespaces_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_runner_projects
    ADD CONSTRAINT ci_runner_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_runners
    ADD CONSTRAINT ci_runners_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT ci_sources_pipelines_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_sources_projects
    ADD CONSTRAINT ci_sources_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_stages
    ADD CONSTRAINT ci_stages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_subscriptions_projects
    ADD CONSTRAINT ci_subscriptions_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_trigger_requests
    ADD CONSTRAINT ci_trigger_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_triggers
    ADD CONSTRAINT ci_triggers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ci_variables
    ADD CONSTRAINT ci_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.cluster_groups
    ADD CONSTRAINT cluster_groups_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.cluster_platforms_kubernetes
    ADD CONSTRAINT cluster_platforms_kubernetes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.cluster_projects
    ADD CONSTRAINT cluster_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.cluster_providers_aws
    ADD CONSTRAINT cluster_providers_aws_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.cluster_providers_gcp
    ADD CONSTRAINT cluster_providers_gcp_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_cert_managers
    ADD CONSTRAINT clusters_applications_cert_managers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_crossplane
    ADD CONSTRAINT clusters_applications_crossplane_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_elastic_stacks
    ADD CONSTRAINT clusters_applications_elastic_stacks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_fluentd
    ADD CONSTRAINT clusters_applications_fluentd_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_helm
    ADD CONSTRAINT clusters_applications_helm_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_ingress
    ADD CONSTRAINT clusters_applications_ingress_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_jupyter
    ADD CONSTRAINT clusters_applications_jupyter_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_knative
    ADD CONSTRAINT clusters_applications_knative_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_prometheus
    ADD CONSTRAINT clusters_applications_prometheus_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_applications_runners
    ADD CONSTRAINT clusters_applications_runners_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters_kubernetes_namespaces
    ADD CONSTRAINT clusters_kubernetes_namespaces_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.clusters
    ADD CONSTRAINT clusters_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.commit_user_mentions
    ADD CONSTRAINT commit_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.container_expiration_policies
    ADD CONSTRAINT container_expiration_policies_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.container_repositories
    ADD CONSTRAINT container_repositories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.conversational_development_index_metrics
    ADD CONSTRAINT conversational_development_index_metrics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.dependency_proxy_blobs
    ADD CONSTRAINT dependency_proxy_blobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.dependency_proxy_group_settings
    ADD CONSTRAINT dependency_proxy_group_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.deploy_keys_projects
    ADD CONSTRAINT deploy_keys_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.deploy_tokens
    ADD CONSTRAINT deploy_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.deployment_clusters
    ADD CONSTRAINT deployment_clusters_pkey PRIMARY KEY (deployment_id);

ALTER TABLE ONLY public.deployments
    ADD CONSTRAINT deployments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.description_versions
    ADD CONSTRAINT description_versions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.design_management_designs
    ADD CONSTRAINT design_management_designs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.design_management_designs_versions
    ADD CONSTRAINT design_management_designs_versions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.design_management_versions
    ADD CONSTRAINT design_management_versions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.design_user_mentions
    ADD CONSTRAINT design_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.diff_note_positions
    ADD CONSTRAINT diff_note_positions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.draft_notes
    ADD CONSTRAINT draft_notes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.epic_issues
    ADD CONSTRAINT epic_issues_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.epic_metrics
    ADD CONSTRAINT epic_metrics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.epic_user_mentions
    ADD CONSTRAINT epic_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT epics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.evidences
    ADD CONSTRAINT evidences_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.external_pull_requests
    ADD CONSTRAINT external_pull_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.feature_gates
    ADD CONSTRAINT feature_gates_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.fork_network_members
    ADD CONSTRAINT fork_network_members_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.fork_networks
    ADD CONSTRAINT fork_networks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_cache_invalidation_events
    ADD CONSTRAINT geo_cache_invalidation_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_container_repository_updated_events
    ADD CONSTRAINT geo_container_repository_updated_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT geo_event_log_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_events
    ADD CONSTRAINT geo_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_hashed_storage_attachments_events
    ADD CONSTRAINT geo_hashed_storage_attachments_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_hashed_storage_migrated_events
    ADD CONSTRAINT geo_hashed_storage_migrated_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_job_artifact_deleted_events
    ADD CONSTRAINT geo_job_artifact_deleted_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_lfs_object_deleted_events
    ADD CONSTRAINT geo_lfs_object_deleted_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_node_namespace_links
    ADD CONSTRAINT geo_node_namespace_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_node_statuses
    ADD CONSTRAINT geo_node_statuses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_nodes
    ADD CONSTRAINT geo_nodes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_repositories_changed_events
    ADD CONSTRAINT geo_repositories_changed_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_repository_created_events
    ADD CONSTRAINT geo_repository_created_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_repository_deleted_events
    ADD CONSTRAINT geo_repository_deleted_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_repository_renamed_events
    ADD CONSTRAINT geo_repository_renamed_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_repository_updated_events
    ADD CONSTRAINT geo_repository_updated_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_reset_checksum_events
    ADD CONSTRAINT geo_reset_checksum_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.geo_upload_deleted_events
    ADD CONSTRAINT geo_upload_deleted_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.gitlab_subscription_histories
    ADD CONSTRAINT gitlab_subscription_histories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.gitlab_subscriptions
    ADD CONSTRAINT gitlab_subscriptions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.gpg_key_subkeys
    ADD CONSTRAINT gpg_key_subkeys_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.gpg_keys
    ADD CONSTRAINT gpg_keys_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.gpg_signatures
    ADD CONSTRAINT gpg_signatures_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.grafana_integrations
    ADD CONSTRAINT grafana_integrations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.group_custom_attributes
    ADD CONSTRAINT group_custom_attributes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.group_deletion_schedules
    ADD CONSTRAINT group_deletion_schedules_pkey PRIMARY KEY (group_id);

ALTER TABLE ONLY public.group_deploy_keys
    ADD CONSTRAINT group_deploy_keys_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.group_deploy_tokens
    ADD CONSTRAINT group_deploy_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.group_group_links
    ADD CONSTRAINT group_group_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.group_import_states
    ADD CONSTRAINT group_import_states_pkey PRIMARY KEY (group_id);

ALTER TABLE ONLY public.group_wiki_repositories
    ADD CONSTRAINT group_wiki_repositories_pkey PRIMARY KEY (group_id);

ALTER TABLE ONLY public.historical_data
    ADD CONSTRAINT historical_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.import_export_uploads
    ADD CONSTRAINT import_export_uploads_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.import_failures
    ADD CONSTRAINT import_failures_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.index_statuses
    ADD CONSTRAINT index_statuses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.insights
    ADD CONSTRAINT insights_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.internal_ids
    ADD CONSTRAINT internal_ids_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ip_restrictions
    ADD CONSTRAINT ip_restrictions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.issue_links
    ADD CONSTRAINT issue_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.issue_metrics
    ADD CONSTRAINT issue_metrics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.issue_tracker_data
    ADD CONSTRAINT issue_tracker_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.issue_user_mentions
    ADD CONSTRAINT issue_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.jira_connect_installations
    ADD CONSTRAINT jira_connect_installations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.jira_connect_subscriptions
    ADD CONSTRAINT jira_connect_subscriptions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.jira_imports
    ADD CONSTRAINT jira_imports_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.jira_tracker_data
    ADD CONSTRAINT jira_tracker_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.label_links
    ADD CONSTRAINT label_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.label_priorities
    ADD CONSTRAINT label_priorities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ldap_group_links
    ADD CONSTRAINT ldap_group_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.lfs_file_locks
    ADD CONSTRAINT lfs_file_locks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.lfs_objects
    ADD CONSTRAINT lfs_objects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.lfs_objects_projects
    ADD CONSTRAINT lfs_objects_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.list_user_preferences
    ADD CONSTRAINT list_user_preferences_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT lists_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_request_assignees
    ADD CONSTRAINT merge_request_assignees_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_request_blocks
    ADD CONSTRAINT merge_request_blocks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_request_context_commits
    ADD CONSTRAINT merge_request_context_commits_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_request_diffs
    ADD CONSTRAINT merge_request_diffs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_request_metrics
    ADD CONSTRAINT merge_request_metrics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_request_user_mentions
    ADD CONSTRAINT merge_request_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_requests_closing_issues
    ADD CONSTRAINT merge_requests_closing_issues_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT merge_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.merge_trains
    ADD CONSTRAINT merge_trains_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.metrics_dashboard_annotations
    ADD CONSTRAINT metrics_dashboard_annotations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.metrics_users_starred_dashboards
    ADD CONSTRAINT metrics_users_starred_dashboards_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.milestones
    ADD CONSTRAINT milestones_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.namespace_aggregation_schedules
    ADD CONSTRAINT namespace_aggregation_schedules_pkey PRIMARY KEY (namespace_id);

ALTER TABLE ONLY public.namespace_root_storage_statistics
    ADD CONSTRAINT namespace_root_storage_statistics_pkey PRIMARY KEY (namespace_id);

ALTER TABLE ONLY public.namespace_statistics
    ADD CONSTRAINT namespace_statistics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.note_diff_files
    ADD CONSTRAINT note_diff_files_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.oauth_openid_requests
    ADD CONSTRAINT oauth_openid_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.open_project_tracker_data
    ADD CONSTRAINT open_project_tracker_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_feature_flag_scopes
    ADD CONSTRAINT operations_feature_flag_scopes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_feature_flags_clients
    ADD CONSTRAINT operations_feature_flags_clients_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_feature_flags_issues
    ADD CONSTRAINT operations_feature_flags_issues_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_feature_flags
    ADD CONSTRAINT operations_feature_flags_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_scopes
    ADD CONSTRAINT operations_scopes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_strategies
    ADD CONSTRAINT operations_strategies_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_strategies_user_lists
    ADD CONSTRAINT operations_strategies_user_lists_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.operations_user_lists
    ADD CONSTRAINT operations_user_lists_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_build_infos
    ADD CONSTRAINT packages_build_infos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_composer_metadata
    ADD CONSTRAINT packages_composer_metadata_pkey PRIMARY KEY (package_id);

ALTER TABLE ONLY public.packages_conan_file_metadata
    ADD CONSTRAINT packages_conan_file_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_conan_metadata
    ADD CONSTRAINT packages_conan_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_dependencies
    ADD CONSTRAINT packages_dependencies_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_dependency_links
    ADD CONSTRAINT packages_dependency_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_maven_metadata
    ADD CONSTRAINT packages_maven_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_nuget_dependency_link_metadata
    ADD CONSTRAINT packages_nuget_dependency_link_metadata_pkey PRIMARY KEY (dependency_link_id);

ALTER TABLE ONLY public.packages_nuget_metadata
    ADD CONSTRAINT packages_nuget_metadata_pkey PRIMARY KEY (package_id);

ALTER TABLE ONLY public.packages_package_files
    ADD CONSTRAINT packages_package_files_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_packages
    ADD CONSTRAINT packages_packages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.packages_pypi_metadata
    ADD CONSTRAINT packages_pypi_metadata_pkey PRIMARY KEY (package_id);

ALTER TABLE ONLY public.packages_tags
    ADD CONSTRAINT packages_tags_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.pages_domain_acme_orders
    ADD CONSTRAINT pages_domain_acme_orders_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.pages_domains
    ADD CONSTRAINT pages_domains_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.partitioned_foreign_keys
    ADD CONSTRAINT partitioned_foreign_keys_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.path_locks
    ADD CONSTRAINT path_locks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.plan_limits
    ADD CONSTRAINT plan_limits_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.pool_repositories
    ADD CONSTRAINT pool_repositories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.programming_languages
    ADD CONSTRAINT programming_languages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_alerting_settings
    ADD CONSTRAINT project_alerting_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_aliases
    ADD CONSTRAINT project_aliases_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_auto_devops
    ADD CONSTRAINT project_auto_devops_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_ci_cd_settings
    ADD CONSTRAINT project_ci_cd_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_compliance_framework_settings
    ADD CONSTRAINT project_compliance_framework_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_custom_attributes
    ADD CONSTRAINT project_custom_attributes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_daily_statistics
    ADD CONSTRAINT project_daily_statistics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_deploy_tokens
    ADD CONSTRAINT project_deploy_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_error_tracking_settings
    ADD CONSTRAINT project_error_tracking_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_export_jobs
    ADD CONSTRAINT project_export_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_feature_usages
    ADD CONSTRAINT project_feature_usages_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_features
    ADD CONSTRAINT project_features_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_group_links
    ADD CONSTRAINT project_group_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_import_data
    ADD CONSTRAINT project_import_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_incident_management_settings
    ADD CONSTRAINT project_incident_management_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_metrics_settings
    ADD CONSTRAINT project_metrics_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_mirror_data
    ADD CONSTRAINT project_mirror_data_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_repositories
    ADD CONSTRAINT project_repositories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_repository_states
    ADD CONSTRAINT project_repository_states_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_repository_storage_moves
    ADD CONSTRAINT project_repository_storage_moves_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_security_settings
    ADD CONSTRAINT project_security_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_settings
    ADD CONSTRAINT project_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.project_statistics
    ADD CONSTRAINT project_statistics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.project_tracing_settings
    ADD CONSTRAINT project_tracing_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.prometheus_alert_events
    ADD CONSTRAINT prometheus_alert_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.prometheus_alerts
    ADD CONSTRAINT prometheus_alerts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.prometheus_metrics
    ADD CONSTRAINT prometheus_metrics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_branch_merge_access_levels
    ADD CONSTRAINT protected_branch_merge_access_levels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_branch_push_access_levels
    ADD CONSTRAINT protected_branch_push_access_levels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_branch_unprotect_access_levels
    ADD CONSTRAINT protected_branch_unprotect_access_levels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_branches
    ADD CONSTRAINT protected_branches_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_environment_deploy_access_levels
    ADD CONSTRAINT protected_environment_deploy_access_levels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_environments
    ADD CONSTRAINT protected_environments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_tag_create_access_levels
    ADD CONSTRAINT protected_tag_create_access_levels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.protected_tags
    ADD CONSTRAINT protected_tags_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.push_rules
    ADD CONSTRAINT push_rules_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.redirect_routes
    ADD CONSTRAINT redirect_routes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.release_links
    ADD CONSTRAINT release_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.remote_mirrors
    ADD CONSTRAINT remote_mirrors_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.requirements_management_test_reports
    ADD CONSTRAINT requirements_management_test_reports_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT requirements_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.resource_label_events
    ADD CONSTRAINT resource_label_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.resource_milestone_events
    ADD CONSTRAINT resource_milestone_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.resource_state_events
    ADD CONSTRAINT resource_state_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.resource_weight_events
    ADD CONSTRAINT resource_weight_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);

ALTER TABLE ONLY public.scim_identities
    ADD CONSTRAINT scim_identities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.scim_oauth_access_tokens
    ADD CONSTRAINT scim_oauth_access_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.security_scans
    ADD CONSTRAINT security_scans_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.self_managed_prometheus_alert_events
    ADD CONSTRAINT self_managed_prometheus_alert_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.sent_notifications
    ADD CONSTRAINT sent_notifications_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.sentry_issues
    ADD CONSTRAINT sentry_issues_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.serverless_domain_cluster
    ADD CONSTRAINT serverless_domain_cluster_pkey PRIMARY KEY (uuid);

ALTER TABLE ONLY public.service_desk_settings
    ADD CONSTRAINT service_desk_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.shards
    ADD CONSTRAINT shards_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.slack_integrations
    ADD CONSTRAINT slack_integrations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.smartcard_identities
    ADD CONSTRAINT smartcard_identities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.snippet_repositories
    ADD CONSTRAINT snippet_repositories_pkey PRIMARY KEY (snippet_id);

ALTER TABLE ONLY public.snippet_user_mentions
    ADD CONSTRAINT snippet_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.snippets
    ADD CONSTRAINT snippets_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.software_license_policies
    ADD CONSTRAINT software_license_policies_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.software_licenses
    ADD CONSTRAINT software_licenses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.spam_logs
    ADD CONSTRAINT spam_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.sprints
    ADD CONSTRAINT sprints_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.status_page_published_incidents
    ADD CONSTRAINT status_page_published_incidents_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.status_page_settings
    ADD CONSTRAINT status_page_settings_pkey PRIMARY KEY (project_id);

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.suggestions
    ADD CONSTRAINT suggestions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.system_note_metadata
    ADD CONSTRAINT system_note_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.term_agreements
    ADD CONSTRAINT term_agreements_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.terraform_states
    ADD CONSTRAINT terraform_states_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.timelogs
    ADD CONSTRAINT timelogs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT todos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.trending_projects
    ADD CONSTRAINT trending_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.u2f_registrations
    ADD CONSTRAINT u2f_registrations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_agent_details
    ADD CONSTRAINT user_agent_details_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_callouts
    ADD CONSTRAINT user_callouts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_canonical_emails
    ADD CONSTRAINT user_canonical_emails_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_custom_attributes
    ADD CONSTRAINT user_custom_attributes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_details
    ADD CONSTRAINT user_details_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY public.user_highest_roles
    ADD CONSTRAINT user_highest_roles_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_statuses
    ADD CONSTRAINT user_statuses_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY public.user_synced_attributes_metadata
    ADD CONSTRAINT user_synced_attributes_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users_ops_dashboard_projects
    ADD CONSTRAINT users_ops_dashboard_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users_star_projects
    ADD CONSTRAINT users_star_projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users_statistics
    ADD CONSTRAINT users_statistics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT vulnerabilities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_exports
    ADD CONSTRAINT vulnerability_exports_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT vulnerability_feedback_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_identifiers
    ADD CONSTRAINT vulnerability_identifiers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_issue_links
    ADD CONSTRAINT vulnerability_issue_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_occurrence_identifiers
    ADD CONSTRAINT vulnerability_occurrence_identifiers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_occurrence_pipelines
    ADD CONSTRAINT vulnerability_occurrence_pipelines_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_occurrences
    ADD CONSTRAINT vulnerability_occurrences_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_scanners
    ADD CONSTRAINT vulnerability_scanners_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.vulnerability_user_mentions
    ADD CONSTRAINT vulnerability_user_mentions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.web_hook_logs
    ADD CONSTRAINT web_hook_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.web_hooks
    ADD CONSTRAINT web_hooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.wiki_page_meta
    ADD CONSTRAINT wiki_page_meta_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.wiki_page_slugs
    ADD CONSTRAINT wiki_page_slugs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.x509_certificates
    ADD CONSTRAINT x509_certificates_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.x509_commit_signatures
    ADD CONSTRAINT x509_commit_signatures_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.x509_issuers
    ADD CONSTRAINT x509_issuers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.zoom_meetings
    ADD CONSTRAINT zoom_meetings_pkey PRIMARY KEY (id);

CREATE INDEX analytics_index_audit_events_on_created_at_and_author_id ON public.audit_events USING btree (created_at, author_id);

CREATE INDEX analytics_index_events_on_created_at_and_author_id ON public.events USING btree (created_at, author_id);

CREATE INDEX analytics_repository_languages_on_project_id ON public.analytics_language_trend_repository_languages USING btree (project_id);

CREATE UNIQUE INDEX analytics_repository_languages_unique_index ON public.analytics_language_trend_repository_languages USING btree (programming_language_id, project_id, snapshot_date);

CREATE UNIQUE INDEX any_approver_merge_request_rule_type_unique_index ON public.approval_merge_request_rules USING btree (merge_request_id, rule_type) WHERE (rule_type = 4);

CREATE UNIQUE INDEX any_approver_project_rule_type_unique_index ON public.approval_project_rules USING btree (project_id) WHERE (rule_type = 3);

CREATE UNIQUE INDEX approval_rule_name_index_for_code_owners ON public.approval_merge_request_rules USING btree (merge_request_id, code_owner, name) WHERE (code_owner = true);

CREATE INDEX ci_builds_gitlab_monitor_metrics ON public.ci_builds USING btree (status, created_at, project_id) WHERE ((type)::text = 'Ci::Build'::text);

CREATE INDEX code_owner_approval_required ON public.protected_branches USING btree (project_id, code_owner_approval_required) WHERE (code_owner_approval_required = true);

CREATE INDEX commit_id_and_note_id_index ON public.commit_user_mentions USING btree (commit_id, note_id);

CREATE UNIQUE INDEX design_management_designs_versions_uniqueness ON public.design_management_designs_versions USING btree (design_id, version_id);

CREATE INDEX design_user_mentions_on_design_id_and_note_id_index ON public.design_user_mentions USING btree (design_id, note_id);

CREATE INDEX dev_index_route_on_path_trigram ON public.routes USING gin (path public.gin_trgm_ops);

CREATE UNIQUE INDEX epic_user_mentions_on_epic_id_and_note_id_index ON public.epic_user_mentions USING btree (epic_id, note_id);

CREATE UNIQUE INDEX epic_user_mentions_on_epic_id_index ON public.epic_user_mentions USING btree (epic_id) WHERE (note_id IS NULL);

CREATE INDEX idx_deployment_clusters_on_cluster_id_and_kubernetes_namespace ON public.deployment_clusters USING btree (cluster_id, kubernetes_namespace);

CREATE UNIQUE INDEX idx_deployment_merge_requests_unique_index ON public.deployment_merge_requests USING btree (deployment_id, merge_request_id);

CREATE UNIQUE INDEX idx_environment_merge_requests_unique_index ON public.deployment_merge_requests USING btree (environment_id, merge_request_id);

CREATE INDEX idx_geo_con_rep_updated_events_on_container_repository_id ON public.geo_container_repository_updated_events USING btree (container_repository_id);

CREATE INDEX idx_issues_on_health_status_not_null ON public.issues USING btree (health_status) WHERE (health_status IS NOT NULL);

CREATE INDEX idx_issues_on_project_id_and_created_at_and_id_and_state_id ON public.issues USING btree (project_id, created_at, id, state_id);

CREATE INDEX idx_issues_on_project_id_and_due_date_and_id_and_state_id ON public.issues USING btree (project_id, due_date, id, state_id) WHERE (due_date IS NOT NULL);

CREATE INDEX idx_issues_on_project_id_and_rel_position_and_state_id_and_id ON public.issues USING btree (project_id, relative_position, state_id, id DESC);

CREATE INDEX idx_issues_on_project_id_and_updated_at_and_id_and_state_id ON public.issues USING btree (project_id, updated_at, id, state_id);

CREATE INDEX idx_issues_on_state_id ON public.issues USING btree (state_id);

CREATE INDEX idx_jira_connect_subscriptions_on_installation_id ON public.jira_connect_subscriptions USING btree (jira_connect_installation_id);

CREATE UNIQUE INDEX idx_jira_connect_subscriptions_on_installation_id_namespace_id ON public.jira_connect_subscriptions USING btree (jira_connect_installation_id, namespace_id);

CREATE INDEX idx_merge_requests_on_id_and_merge_jid ON public.merge_requests USING btree (id, merge_jid) WHERE ((merge_jid IS NOT NULL) AND (state_id = 4));

CREATE INDEX idx_merge_requests_on_source_project_and_branch_state_opened ON public.merge_requests USING btree (source_project_id, source_branch) WHERE (state_id = 1);

CREATE INDEX idx_merge_requests_on_state_id_and_merge_status ON public.merge_requests USING btree (state_id, merge_status) WHERE ((state_id = 1) AND ((merge_status)::text = 'can_be_merged'::text));

CREATE INDEX idx_merge_requests_on_target_project_id_and_iid_opened ON public.merge_requests USING btree (target_project_id, iid) WHERE (state_id = 1);

CREATE INDEX idx_merge_requests_on_target_project_id_and_locked_state ON public.merge_requests USING btree (target_project_id) WHERE (state_id = 4);

CREATE UNIQUE INDEX idx_metrics_users_starred_dashboard_on_user_project_dashboard ON public.metrics_users_starred_dashboards USING btree (user_id, project_id, dashboard_path);

CREATE INDEX idx_mr_cc_diff_files_on_mr_cc_id_and_sha ON public.merge_request_context_commit_diff_files USING btree (merge_request_context_commit_id, sha);

CREATE INDEX idx_packages_packages_on_project_id_name_version_package_type ON public.packages_packages USING btree (project_id, name, version, package_type);

CREATE UNIQUE INDEX idx_pkgs_dep_links_on_pkg_id_dependency_id_dependency_type ON public.packages_dependency_links USING btree (package_id, dependency_id, dependency_type);

CREATE INDEX idx_proj_feat_usg_on_jira_dvcs_cloud_last_sync_at_and_proj_id ON public.project_feature_usages USING btree (jira_dvcs_cloud_last_sync_at, project_id) WHERE (jira_dvcs_cloud_last_sync_at IS NOT NULL);

CREATE INDEX idx_proj_feat_usg_on_jira_dvcs_server_last_sync_at_and_proj_id ON public.project_feature_usages USING btree (jira_dvcs_server_last_sync_at, project_id) WHERE (jira_dvcs_server_last_sync_at IS NOT NULL);

CREATE UNIQUE INDEX idx_project_id_payload_key_self_managed_prometheus_alert_events ON public.self_managed_prometheus_alert_events USING btree (project_id, payload_key);

CREATE INDEX idx_project_repository_check_partial ON public.projects USING btree (repository_storage, created_at) WHERE (last_repository_check_at IS NULL);

CREATE INDEX idx_projects_on_repository_storage_last_repository_updated_at ON public.projects USING btree (id, repository_storage, last_repository_updated_at);

CREATE INDEX idx_repository_states_on_last_repository_verification_ran_at ON public.project_repository_states USING btree (project_id, last_repository_verification_ran_at) WHERE ((repository_verification_checksum IS NOT NULL) AND (last_repository_verification_failure IS NULL));

CREATE INDEX idx_repository_states_on_last_wiki_verification_ran_at ON public.project_repository_states USING btree (project_id, last_wiki_verification_ran_at) WHERE ((wiki_verification_checksum IS NOT NULL) AND (last_wiki_verification_failure IS NULL));

CREATE INDEX idx_repository_states_on_repository_failure_partial ON public.project_repository_states USING btree (last_repository_verification_failure) WHERE (last_repository_verification_failure IS NOT NULL);

CREATE INDEX idx_repository_states_on_wiki_failure_partial ON public.project_repository_states USING btree (last_wiki_verification_failure) WHERE (last_wiki_verification_failure IS NOT NULL);

CREATE INDEX idx_repository_states_outdated_checksums ON public.project_repository_states USING btree (project_id) WHERE (((repository_verification_checksum IS NULL) AND (last_repository_verification_failure IS NULL)) OR ((wiki_verification_checksum IS NULL) AND (last_wiki_verification_failure IS NULL)));

CREATE UNIQUE INDEX idx_security_scans_on_build_and_scan_type ON public.security_scans USING btree (build_id, scan_type);

CREATE INDEX idx_security_scans_on_scan_type ON public.security_scans USING btree (scan_type);

CREATE UNIQUE INDEX idx_serverless_domain_cluster_on_clusters_applications_knative ON public.serverless_domain_cluster USING btree (clusters_applications_knative_id);

CREATE UNIQUE INDEX idx_vulnerability_issue_links_on_vulnerability_id_and_issue_id ON public.vulnerability_issue_links USING btree (vulnerability_id, issue_id);

CREATE UNIQUE INDEX idx_vulnerability_issue_links_on_vulnerability_id_and_link_type ON public.vulnerability_issue_links USING btree (vulnerability_id, link_type) WHERE (link_type = 2);

CREATE INDEX index_abuse_reports_on_user_id ON public.abuse_reports USING btree (user_id);

CREATE INDEX index_alert_assignees_on_alert_id ON public.alert_management_alert_assignees USING btree (alert_id);

CREATE UNIQUE INDEX index_alert_assignees_on_user_id_and_alert_id ON public.alert_management_alert_assignees USING btree (user_id, alert_id);

CREATE INDEX index_alert_management_alerts_on_issue_id ON public.alert_management_alerts USING btree (issue_id);

CREATE UNIQUE INDEX index_alert_management_alerts_on_project_id_and_fingerprint ON public.alert_management_alerts USING btree (project_id, fingerprint);

CREATE UNIQUE INDEX index_alert_management_alerts_on_project_id_and_iid ON public.alert_management_alerts USING btree (project_id, iid);

CREATE UNIQUE INDEX index_alert_user_mentions_on_alert_id ON public.alert_management_alert_user_mentions USING btree (alert_management_alert_id) WHERE (note_id IS NULL);

CREATE UNIQUE INDEX index_alert_user_mentions_on_alert_id_and_note_id ON public.alert_management_alert_user_mentions USING btree (alert_management_alert_id, note_id);

CREATE UNIQUE INDEX index_alert_user_mentions_on_note_id ON public.alert_management_alert_user_mentions USING btree (note_id) WHERE (note_id IS NOT NULL);

CREATE INDEX index_alerts_service_data_on_service_id ON public.alerts_service_data USING btree (service_id);

CREATE INDEX index_allowed_email_domains_on_group_id ON public.allowed_email_domains USING btree (group_id);

CREATE INDEX index_analytics_ca_group_stages_on_end_event_label_id ON public.analytics_cycle_analytics_group_stages USING btree (end_event_label_id);

CREATE INDEX index_analytics_ca_group_stages_on_group_id ON public.analytics_cycle_analytics_group_stages USING btree (group_id);

CREATE UNIQUE INDEX index_analytics_ca_group_stages_on_group_id_and_name ON public.analytics_cycle_analytics_group_stages USING btree (group_id, name);

CREATE INDEX index_analytics_ca_group_stages_on_relative_position ON public.analytics_cycle_analytics_group_stages USING btree (relative_position);

CREATE INDEX index_analytics_ca_group_stages_on_start_event_label_id ON public.analytics_cycle_analytics_group_stages USING btree (start_event_label_id);

CREATE INDEX index_analytics_ca_project_stages_on_end_event_label_id ON public.analytics_cycle_analytics_project_stages USING btree (end_event_label_id);

CREATE INDEX index_analytics_ca_project_stages_on_project_id ON public.analytics_cycle_analytics_project_stages USING btree (project_id);

CREATE UNIQUE INDEX index_analytics_ca_project_stages_on_project_id_and_name ON public.analytics_cycle_analytics_project_stages USING btree (project_id, name);

CREATE INDEX index_analytics_ca_project_stages_on_relative_position ON public.analytics_cycle_analytics_project_stages USING btree (relative_position);

CREATE INDEX index_analytics_ca_project_stages_on_start_event_label_id ON public.analytics_cycle_analytics_project_stages USING btree (start_event_label_id);

CREATE INDEX index_analytics_cycle_analytics_group_stages_custom_only ON public.analytics_cycle_analytics_group_stages USING btree (id) WHERE (custom = true);

CREATE INDEX index_application_settings_on_custom_project_templates_group_id ON public.application_settings USING btree (custom_project_templates_group_id);

CREATE INDEX index_application_settings_on_file_template_project_id ON public.application_settings USING btree (file_template_project_id);

CREATE INDEX index_application_settings_on_instance_administrators_group_id ON public.application_settings USING btree (instance_administrators_group_id);

CREATE UNIQUE INDEX index_application_settings_on_push_rule_id ON public.application_settings USING btree (push_rule_id);

CREATE INDEX index_application_settings_on_usage_stats_set_by_user_id ON public.application_settings USING btree (usage_stats_set_by_user_id);

CREATE INDEX index_applicationsettings_on_instance_administration_project_id ON public.application_settings USING btree (instance_administration_project_id);

CREATE UNIQUE INDEX index_approval_merge_request_rule_sources_1 ON public.approval_merge_request_rule_sources USING btree (approval_merge_request_rule_id);

CREATE INDEX index_approval_merge_request_rule_sources_2 ON public.approval_merge_request_rule_sources USING btree (approval_project_rule_id);

CREATE INDEX index_approval_merge_request_rules_1 ON public.approval_merge_request_rules USING btree (merge_request_id, code_owner);

CREATE UNIQUE INDEX index_approval_merge_request_rules_approved_approvers_1 ON public.approval_merge_request_rules_approved_approvers USING btree (approval_merge_request_rule_id, user_id);

CREATE INDEX index_approval_merge_request_rules_approved_approvers_2 ON public.approval_merge_request_rules_approved_approvers USING btree (user_id);

CREATE UNIQUE INDEX index_approval_merge_request_rules_groups_1 ON public.approval_merge_request_rules_groups USING btree (approval_merge_request_rule_id, group_id);

CREATE INDEX index_approval_merge_request_rules_groups_2 ON public.approval_merge_request_rules_groups USING btree (group_id);

CREATE UNIQUE INDEX index_approval_merge_request_rules_users_1 ON public.approval_merge_request_rules_users USING btree (approval_merge_request_rule_id, user_id);

CREATE INDEX index_approval_merge_request_rules_users_2 ON public.approval_merge_request_rules_users USING btree (user_id);

CREATE UNIQUE INDEX index_approval_project_rules_groups_1 ON public.approval_project_rules_groups USING btree (approval_project_rule_id, group_id);

CREATE INDEX index_approval_project_rules_groups_2 ON public.approval_project_rules_groups USING btree (group_id);

CREATE INDEX index_approval_project_rules_on_project_id ON public.approval_project_rules USING btree (project_id);

CREATE INDEX index_approval_project_rules_on_rule_type ON public.approval_project_rules USING btree (rule_type);

CREATE INDEX index_approval_project_rules_protected_branches_pb_id ON public.approval_project_rules_protected_branches USING btree (protected_branch_id);

CREATE UNIQUE INDEX index_approval_project_rules_protected_branches_unique ON public.approval_project_rules_protected_branches USING btree (approval_project_rule_id, protected_branch_id);

CREATE UNIQUE INDEX index_approval_project_rules_users_1 ON public.approval_project_rules_users USING btree (approval_project_rule_id, user_id);

CREATE INDEX index_approval_project_rules_users_2 ON public.approval_project_rules_users USING btree (user_id);

CREATE UNIQUE INDEX index_approval_rule_name_for_code_owners_rule_type ON public.approval_merge_request_rules USING btree (merge_request_id, name) WHERE (rule_type = 2);

CREATE INDEX index_approval_rules_code_owners_rule_type ON public.approval_merge_request_rules USING btree (merge_request_id) WHERE (rule_type = 2);

CREATE INDEX index_approvals_on_merge_request_id ON public.approvals USING btree (merge_request_id);

CREATE UNIQUE INDEX index_approvals_on_user_id_and_merge_request_id ON public.approvals USING btree (user_id, merge_request_id);

CREATE INDEX index_approver_groups_on_group_id ON public.approver_groups USING btree (group_id);

CREATE INDEX index_approver_groups_on_target_id_and_target_type ON public.approver_groups USING btree (target_id, target_type);

CREATE INDEX index_approvers_on_target_id_and_target_type ON public.approvers USING btree (target_id, target_type);

CREATE INDEX index_approvers_on_user_id ON public.approvers USING btree (user_id);

CREATE INDEX index_audit_events_on_entity_id_and_entity_type_and_id_desc ON public.audit_events USING btree (entity_id, entity_type, id DESC);

CREATE INDEX index_audit_events_on_ruby_object_in_details ON public.audit_events USING btree (id) WHERE (details ~~ '%ruby/object%'::text);

CREATE INDEX index_award_emoji_on_awardable_type_and_awardable_id ON public.award_emoji USING btree (awardable_type, awardable_id);

CREATE INDEX index_award_emoji_on_user_id_and_name ON public.award_emoji USING btree (user_id, name);

CREATE UNIQUE INDEX index_aws_roles_on_role_external_id ON public.aws_roles USING btree (role_external_id);

CREATE UNIQUE INDEX index_aws_roles_on_user_id ON public.aws_roles USING btree (user_id);

CREATE INDEX index_badges_on_group_id ON public.badges USING btree (group_id);

CREATE INDEX index_badges_on_project_id ON public.badges USING btree (project_id);

CREATE INDEX index_board_assignees_on_assignee_id ON public.board_assignees USING btree (assignee_id);

CREATE UNIQUE INDEX index_board_assignees_on_board_id_and_assignee_id ON public.board_assignees USING btree (board_id, assignee_id);

CREATE INDEX index_board_group_recent_visits_on_board_id ON public.board_group_recent_visits USING btree (board_id);

CREATE INDEX index_board_group_recent_visits_on_group_id ON public.board_group_recent_visits USING btree (group_id);

CREATE UNIQUE INDEX index_board_group_recent_visits_on_user_group_and_board ON public.board_group_recent_visits USING btree (user_id, group_id, board_id);

CREATE INDEX index_board_group_recent_visits_on_user_id ON public.board_group_recent_visits USING btree (user_id);

CREATE UNIQUE INDEX index_board_labels_on_board_id_and_label_id ON public.board_labels USING btree (board_id, label_id);

CREATE INDEX index_board_labels_on_label_id ON public.board_labels USING btree (label_id);

CREATE INDEX index_board_project_recent_visits_on_board_id ON public.board_project_recent_visits USING btree (board_id);

CREATE INDEX index_board_project_recent_visits_on_project_id ON public.board_project_recent_visits USING btree (project_id);

CREATE INDEX index_board_project_recent_visits_on_user_id ON public.board_project_recent_visits USING btree (user_id);

CREATE UNIQUE INDEX index_board_project_recent_visits_on_user_project_and_board ON public.board_project_recent_visits USING btree (user_id, project_id, board_id);

CREATE INDEX index_board_user_preferences_on_board_id ON public.board_user_preferences USING btree (board_id);

CREATE INDEX index_board_user_preferences_on_user_id ON public.board_user_preferences USING btree (user_id);

CREATE UNIQUE INDEX index_board_user_preferences_on_user_id_and_board_id ON public.board_user_preferences USING btree (user_id, board_id);

CREATE INDEX index_boards_on_group_id ON public.boards USING btree (group_id);

CREATE INDEX index_boards_on_milestone_id ON public.boards USING btree (milestone_id);

CREATE INDEX index_boards_on_project_id ON public.boards USING btree (project_id);

CREATE INDEX index_broadcast_message_on_ends_at_and_broadcast_type_and_id ON public.broadcast_messages USING btree (ends_at, broadcast_type, id);

CREATE INDEX index_chat_names_on_service_id ON public.chat_names USING btree (service_id);

CREATE UNIQUE INDEX index_chat_names_on_service_id_and_team_id_and_chat_id ON public.chat_names USING btree (service_id, team_id, chat_id);

CREATE UNIQUE INDEX index_chat_names_on_user_id_and_service_id ON public.chat_names USING btree (user_id, service_id);

CREATE UNIQUE INDEX index_chat_teams_on_namespace_id ON public.chat_teams USING btree (namespace_id);

CREATE UNIQUE INDEX index_ci_build_needs_on_build_id_and_name ON public.ci_build_needs USING btree (build_id, name);

CREATE INDEX index_ci_build_report_results_on_project_id ON public.ci_build_report_results USING btree (project_id);

CREATE UNIQUE INDEX index_ci_build_trace_chunks_on_build_id_and_chunk_index ON public.ci_build_trace_chunks USING btree (build_id, chunk_index);

CREATE UNIQUE INDEX index_ci_build_trace_section_names_on_project_id_and_name ON public.ci_build_trace_section_names USING btree (project_id, name);

CREATE UNIQUE INDEX index_ci_build_trace_sections_on_build_id_and_section_name_id ON public.ci_build_trace_sections USING btree (build_id, section_name_id);

CREATE INDEX index_ci_build_trace_sections_on_project_id ON public.ci_build_trace_sections USING btree (project_id);

CREATE INDEX index_ci_build_trace_sections_on_section_name_id ON public.ci_build_trace_sections USING btree (section_name_id);

CREATE UNIQUE INDEX index_ci_builds_metadata_on_build_id ON public.ci_builds_metadata USING btree (build_id);

CREATE INDEX index_ci_builds_metadata_on_build_id_and_has_exposed_artifacts ON public.ci_builds_metadata USING btree (build_id) WHERE (has_exposed_artifacts IS TRUE);

CREATE INDEX index_ci_builds_metadata_on_build_id_and_interruptible ON public.ci_builds_metadata USING btree (build_id) WHERE (interruptible = true);

CREATE INDEX index_ci_builds_metadata_on_project_id ON public.ci_builds_metadata USING btree (project_id);

CREATE INDEX index_ci_builds_on_artifacts_expire_at ON public.ci_builds USING btree (artifacts_expire_at) WHERE (artifacts_file <> ''::text);

CREATE INDEX index_ci_builds_on_auto_canceled_by_id ON public.ci_builds USING btree (auto_canceled_by_id);

CREATE INDEX index_ci_builds_on_commit_id_and_stage_idx_and_created_at ON public.ci_builds USING btree (commit_id, stage_idx, created_at);

CREATE INDEX index_ci_builds_on_commit_id_and_status_and_type ON public.ci_builds USING btree (commit_id, status, type);

CREATE INDEX index_ci_builds_on_commit_id_and_type_and_name_and_ref ON public.ci_builds USING btree (commit_id, type, name, ref);

CREATE INDEX index_ci_builds_on_commit_id_and_type_and_ref ON public.ci_builds USING btree (commit_id, type, ref);

CREATE INDEX index_ci_builds_on_commit_id_artifacts_expired_at_and_id ON public.ci_builds USING btree (commit_id, artifacts_expire_at, id) WHERE (((type)::text = 'Ci::Build'::text) AND ((retried = false) OR (retried IS NULL)) AND ((name)::text = ANY (ARRAY[('sast'::character varying)::text, ('secret_detection'::character varying)::text, ('dependency_scanning'::character varying)::text, ('container_scanning'::character varying)::text, ('dast'::character varying)::text])));

CREATE INDEX index_ci_builds_on_project_id_and_id ON public.ci_builds USING btree (project_id, id);

CREATE INDEX index_ci_builds_on_project_id_and_name_and_ref ON public.ci_builds USING btree (project_id, name, ref) WHERE (((type)::text = 'Ci::Build'::text) AND ((status)::text = 'success'::text) AND ((retried = false) OR (retried IS NULL)));

CREATE INDEX index_ci_builds_on_project_id_for_successfull_pages_deploy ON public.ci_builds USING btree (project_id) WHERE (((type)::text = 'GenericCommitStatus'::text) AND ((stage)::text = 'deploy'::text) AND ((name)::text = 'pages:deploy'::text) AND ((status)::text = 'success'::text));

CREATE INDEX index_ci_builds_on_protected ON public.ci_builds USING btree (protected);

CREATE INDEX index_ci_builds_on_queued_at ON public.ci_builds USING btree (queued_at);

CREATE INDEX index_ci_builds_on_runner_id ON public.ci_builds USING btree (runner_id);

CREATE INDEX index_ci_builds_on_stage_id ON public.ci_builds USING btree (stage_id);

CREATE INDEX index_ci_builds_on_status_and_type_and_runner_id ON public.ci_builds USING btree (status, type, runner_id);

CREATE UNIQUE INDEX index_ci_builds_on_token ON public.ci_builds USING btree (token);

CREATE UNIQUE INDEX index_ci_builds_on_token_encrypted ON public.ci_builds USING btree (token_encrypted) WHERE (token_encrypted IS NOT NULL);

CREATE INDEX index_ci_builds_on_updated_at ON public.ci_builds USING btree (updated_at);

CREATE INDEX index_ci_builds_on_upstream_pipeline_id ON public.ci_builds USING btree (upstream_pipeline_id) WHERE (upstream_pipeline_id IS NOT NULL);

CREATE INDEX index_ci_builds_on_user_id ON public.ci_builds USING btree (user_id);

CREATE INDEX index_ci_builds_on_user_id_and_created_at_and_type_eq_ci_build ON public.ci_builds USING btree (user_id, created_at) WHERE ((type)::text = 'Ci::Build'::text);

CREATE INDEX index_ci_builds_project_id_and_status_for_live_jobs_partial2 ON public.ci_builds USING btree (project_id, status) WHERE (((type)::text = 'Ci::Build'::text) AND ((status)::text = ANY (ARRAY[('running'::character varying)::text, ('pending'::character varying)::text, ('created'::character varying)::text])));

CREATE UNIQUE INDEX index_ci_builds_runner_session_on_build_id ON public.ci_builds_runner_session USING btree (build_id);

CREATE INDEX index_ci_daily_build_group_report_results_on_last_pipeline_id ON public.ci_daily_build_group_report_results USING btree (last_pipeline_id);

CREATE INDEX index_ci_daily_report_results_on_last_pipeline_id ON public.ci_daily_report_results USING btree (last_pipeline_id);

CREATE INDEX index_ci_freeze_periods_on_project_id ON public.ci_freeze_periods USING btree (project_id);

CREATE UNIQUE INDEX index_ci_group_variables_on_group_id_and_key ON public.ci_group_variables USING btree (group_id, key);

CREATE UNIQUE INDEX index_ci_instance_variables_on_key ON public.ci_instance_variables USING btree (key);

CREATE INDEX index_ci_job_artifacts_file_store_is_null ON public.ci_job_artifacts USING btree (id) WHERE (file_store IS NULL);

CREATE INDEX index_ci_job_artifacts_for_terraform_reports ON public.ci_job_artifacts USING btree (project_id, id) WHERE (file_type = 18);

CREATE INDEX index_ci_job_artifacts_on_expire_at_and_job_id ON public.ci_job_artifacts USING btree (expire_at, job_id);

CREATE INDEX index_ci_job_artifacts_on_file_store ON public.ci_job_artifacts USING btree (file_store);

CREATE UNIQUE INDEX index_ci_job_artifacts_on_job_id_and_file_type ON public.ci_job_artifacts USING btree (job_id, file_type);

CREATE INDEX index_ci_job_artifacts_on_project_id ON public.ci_job_artifacts USING btree (project_id);

CREATE INDEX index_ci_job_artifacts_on_project_id_for_security_reports ON public.ci_job_artifacts USING btree (project_id) WHERE (file_type = ANY (ARRAY[5, 6, 7, 8]));

CREATE INDEX index_ci_job_variables_on_job_id ON public.ci_job_variables USING btree (job_id);

CREATE UNIQUE INDEX index_ci_job_variables_on_key_and_job_id ON public.ci_job_variables USING btree (key, job_id);

CREATE INDEX index_ci_pipeline_chat_data_on_chat_name_id ON public.ci_pipeline_chat_data USING btree (chat_name_id);

CREATE UNIQUE INDEX index_ci_pipeline_chat_data_on_pipeline_id ON public.ci_pipeline_chat_data USING btree (pipeline_id);

CREATE UNIQUE INDEX index_ci_pipeline_schedule_variables_on_schedule_id_and_key ON public.ci_pipeline_schedule_variables USING btree (pipeline_schedule_id, key);

CREATE INDEX index_ci_pipeline_schedules_on_next_run_at_and_active ON public.ci_pipeline_schedules USING btree (next_run_at, active);

CREATE INDEX index_ci_pipeline_schedules_on_owner_id ON public.ci_pipeline_schedules USING btree (owner_id);

CREATE INDEX index_ci_pipeline_schedules_on_project_id ON public.ci_pipeline_schedules USING btree (project_id);

CREATE UNIQUE INDEX index_ci_pipeline_variables_on_pipeline_id_and_key ON public.ci_pipeline_variables USING btree (pipeline_id, key);

CREATE INDEX index_ci_pipelines_config_on_pipeline_id ON public.ci_pipelines_config USING btree (pipeline_id);

CREATE INDEX index_ci_pipelines_on_auto_canceled_by_id ON public.ci_pipelines USING btree (auto_canceled_by_id);

CREATE INDEX index_ci_pipelines_on_ci_ref_id ON public.ci_pipelines USING btree (ci_ref_id) WHERE (ci_ref_id IS NOT NULL);

CREATE INDEX index_ci_pipelines_on_external_pull_request_id ON public.ci_pipelines USING btree (external_pull_request_id) WHERE (external_pull_request_id IS NOT NULL);

CREATE INDEX index_ci_pipelines_on_merge_request_id ON public.ci_pipelines USING btree (merge_request_id) WHERE (merge_request_id IS NOT NULL);

CREATE INDEX index_ci_pipelines_on_pipeline_schedule_id ON public.ci_pipelines USING btree (pipeline_schedule_id);

CREATE INDEX index_ci_pipelines_on_project_id_and_id_desc ON public.ci_pipelines USING btree (project_id, id DESC);

CREATE UNIQUE INDEX index_ci_pipelines_on_project_id_and_iid ON public.ci_pipelines USING btree (project_id, iid) WHERE (iid IS NOT NULL);

CREATE INDEX index_ci_pipelines_on_project_id_and_ref_and_status_and_id ON public.ci_pipelines USING btree (project_id, ref, status, id);

CREATE INDEX index_ci_pipelines_on_project_id_and_sha ON public.ci_pipelines USING btree (project_id, sha);

CREATE INDEX index_ci_pipelines_on_project_id_and_source ON public.ci_pipelines USING btree (project_id, source);

CREATE INDEX index_ci_pipelines_on_project_id_and_status_and_config_source ON public.ci_pipelines USING btree (project_id, status, config_source);

CREATE INDEX index_ci_pipelines_on_project_id_and_status_and_updated_at ON public.ci_pipelines USING btree (project_id, status, updated_at);

CREATE INDEX index_ci_pipelines_on_project_id_and_user_id_and_status_and_ref ON public.ci_pipelines USING btree (project_id, user_id, status, ref) WHERE (source <> 12);

CREATE INDEX index_ci_pipelines_on_project_idandrefandiddesc ON public.ci_pipelines USING btree (project_id, ref, id DESC);

CREATE INDEX index_ci_pipelines_on_status ON public.ci_pipelines USING btree (status);

CREATE INDEX index_ci_pipelines_on_user_id_and_created_at_and_source ON public.ci_pipelines USING btree (user_id, created_at, source);

CREATE UNIQUE INDEX index_ci_refs_on_project_id_and_ref_path ON public.ci_refs USING btree (project_id, ref_path);

CREATE UNIQUE INDEX index_ci_resource_groups_on_project_id_and_key ON public.ci_resource_groups USING btree (project_id, key);

CREATE INDEX index_ci_resources_on_build_id ON public.ci_resources USING btree (build_id);

CREATE UNIQUE INDEX index_ci_resources_on_resource_group_id_and_build_id ON public.ci_resources USING btree (resource_group_id, build_id);

CREATE INDEX index_ci_runner_namespaces_on_namespace_id ON public.ci_runner_namespaces USING btree (namespace_id);

CREATE UNIQUE INDEX index_ci_runner_namespaces_on_runner_id_and_namespace_id ON public.ci_runner_namespaces USING btree (runner_id, namespace_id);

CREATE INDEX index_ci_runner_projects_on_project_id ON public.ci_runner_projects USING btree (project_id);

CREATE INDEX index_ci_runner_projects_on_runner_id ON public.ci_runner_projects USING btree (runner_id);

CREATE INDEX index_ci_runners_on_contacted_at ON public.ci_runners USING btree (contacted_at);

CREATE INDEX index_ci_runners_on_is_shared ON public.ci_runners USING btree (is_shared);

CREATE INDEX index_ci_runners_on_locked ON public.ci_runners USING btree (locked);

CREATE INDEX index_ci_runners_on_runner_type ON public.ci_runners USING btree (runner_type);

CREATE INDEX index_ci_runners_on_token ON public.ci_runners USING btree (token);

CREATE INDEX index_ci_runners_on_token_encrypted ON public.ci_runners USING btree (token_encrypted);

CREATE INDEX index_ci_sources_pipelines_on_pipeline_id ON public.ci_sources_pipelines USING btree (pipeline_id);

CREATE INDEX index_ci_sources_pipelines_on_project_id ON public.ci_sources_pipelines USING btree (project_id);

CREATE INDEX index_ci_sources_pipelines_on_source_job_id ON public.ci_sources_pipelines USING btree (source_job_id);

CREATE INDEX index_ci_sources_pipelines_on_source_pipeline_id ON public.ci_sources_pipelines USING btree (source_pipeline_id);

CREATE INDEX index_ci_sources_pipelines_on_source_project_id ON public.ci_sources_pipelines USING btree (source_project_id);

CREATE INDEX index_ci_sources_projects_on_pipeline_id ON public.ci_sources_projects USING btree (pipeline_id);

CREATE UNIQUE INDEX index_ci_sources_projects_on_source_project_id_and_pipeline_id ON public.ci_sources_projects USING btree (source_project_id, pipeline_id);

CREATE INDEX index_ci_stages_on_pipeline_id ON public.ci_stages USING btree (pipeline_id);

CREATE UNIQUE INDEX index_ci_stages_on_pipeline_id_and_name ON public.ci_stages USING btree (pipeline_id, name);

CREATE INDEX index_ci_stages_on_pipeline_id_and_position ON public.ci_stages USING btree (pipeline_id, "position");

CREATE INDEX index_ci_stages_on_project_id ON public.ci_stages USING btree (project_id);

CREATE INDEX index_ci_subscriptions_projects_on_upstream_project_id ON public.ci_subscriptions_projects USING btree (upstream_project_id);

CREATE UNIQUE INDEX index_ci_subscriptions_projects_unique_subscription ON public.ci_subscriptions_projects USING btree (downstream_project_id, upstream_project_id);

CREATE INDEX index_ci_trigger_requests_on_commit_id ON public.ci_trigger_requests USING btree (commit_id);

CREATE INDEX index_ci_trigger_requests_on_trigger_id_and_id ON public.ci_trigger_requests USING btree (trigger_id, id DESC);

CREATE INDEX index_ci_triggers_on_owner_id ON public.ci_triggers USING btree (owner_id);

CREATE INDEX index_ci_triggers_on_project_id ON public.ci_triggers USING btree (project_id);

CREATE UNIQUE INDEX index_ci_variables_on_project_id_and_key_and_environment_scope ON public.ci_variables USING btree (project_id, key, environment_scope);

CREATE UNIQUE INDEX index_cluster_groups_on_cluster_id_and_group_id ON public.cluster_groups USING btree (cluster_id, group_id);

CREATE INDEX index_cluster_groups_on_group_id ON public.cluster_groups USING btree (group_id);

CREATE UNIQUE INDEX index_cluster_platforms_kubernetes_on_cluster_id ON public.cluster_platforms_kubernetes USING btree (cluster_id);

CREATE INDEX index_cluster_projects_on_cluster_id ON public.cluster_projects USING btree (cluster_id);

CREATE INDEX index_cluster_projects_on_project_id ON public.cluster_projects USING btree (project_id);

CREATE UNIQUE INDEX index_cluster_providers_aws_on_cluster_id ON public.cluster_providers_aws USING btree (cluster_id);

CREATE INDEX index_cluster_providers_aws_on_cluster_id_and_status ON public.cluster_providers_aws USING btree (cluster_id, status);

CREATE INDEX index_cluster_providers_aws_on_created_by_user_id ON public.cluster_providers_aws USING btree (created_by_user_id);

CREATE INDEX index_cluster_providers_gcp_on_cloud_run ON public.cluster_providers_gcp USING btree (cloud_run);

CREATE UNIQUE INDEX index_cluster_providers_gcp_on_cluster_id ON public.cluster_providers_gcp USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_cert_managers_on_cluster_id ON public.clusters_applications_cert_managers USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_crossplane_on_cluster_id ON public.clusters_applications_crossplane USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_elastic_stacks_on_cluster_id ON public.clusters_applications_elastic_stacks USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_fluentd_on_cluster_id ON public.clusters_applications_fluentd USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_helm_on_cluster_id ON public.clusters_applications_helm USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_ingress_on_cluster_id ON public.clusters_applications_ingress USING btree (cluster_id);

CREATE INDEX index_clusters_applications_ingress_on_modsecurity ON public.clusters_applications_ingress USING btree (modsecurity_enabled, modsecurity_mode, cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_jupyter_on_cluster_id ON public.clusters_applications_jupyter USING btree (cluster_id);

CREATE INDEX index_clusters_applications_jupyter_on_oauth_application_id ON public.clusters_applications_jupyter USING btree (oauth_application_id);

CREATE UNIQUE INDEX index_clusters_applications_knative_on_cluster_id ON public.clusters_applications_knative USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_prometheus_on_cluster_id ON public.clusters_applications_prometheus USING btree (cluster_id);

CREATE UNIQUE INDEX index_clusters_applications_runners_on_cluster_id ON public.clusters_applications_runners USING btree (cluster_id);

CREATE INDEX index_clusters_applications_runners_on_runner_id ON public.clusters_applications_runners USING btree (runner_id);

CREATE INDEX index_clusters_kubernetes_namespaces_on_cluster_id ON public.clusters_kubernetes_namespaces USING btree (cluster_id);

CREATE INDEX index_clusters_kubernetes_namespaces_on_cluster_project_id ON public.clusters_kubernetes_namespaces USING btree (cluster_project_id);

CREATE INDEX index_clusters_kubernetes_namespaces_on_environment_id ON public.clusters_kubernetes_namespaces USING btree (environment_id);

CREATE INDEX index_clusters_kubernetes_namespaces_on_project_id ON public.clusters_kubernetes_namespaces USING btree (project_id);

CREATE INDEX index_clusters_on_enabled_and_provider_type_and_id ON public.clusters USING btree (enabled, provider_type, id);

CREATE INDEX index_clusters_on_enabled_cluster_type_id_and_created_at ON public.clusters USING btree (enabled, cluster_type, id, created_at);

CREATE INDEX index_clusters_on_management_project_id ON public.clusters USING btree (management_project_id) WHERE (management_project_id IS NOT NULL);

CREATE INDEX index_clusters_on_user_id ON public.clusters USING btree (user_id);

CREATE UNIQUE INDEX index_commit_user_mentions_on_note_id ON public.commit_user_mentions USING btree (note_id);

CREATE INDEX index_container_expiration_policies_on_next_run_at_and_enabled ON public.container_expiration_policies USING btree (next_run_at, enabled);

CREATE INDEX index_container_repositories_on_project_id ON public.container_repositories USING btree (project_id);

CREATE UNIQUE INDEX index_container_repositories_on_project_id_and_name ON public.container_repositories USING btree (project_id, name);

CREATE INDEX index_container_repository_on_name_trigram ON public.container_repositories USING gin (name public.gin_trgm_ops);

CREATE UNIQUE INDEX index_daily_build_group_report_results_unique_columns ON public.ci_daily_build_group_report_results USING btree (project_id, ref_path, date, group_name);

CREATE UNIQUE INDEX index_daily_report_results_unique_columns ON public.ci_daily_report_results USING btree (project_id, ref_path, param_type, date, title);

CREATE INDEX index_dependency_proxy_blobs_on_group_id_and_file_name ON public.dependency_proxy_blobs USING btree (group_id, file_name);

CREATE INDEX index_dependency_proxy_group_settings_on_group_id ON public.dependency_proxy_group_settings USING btree (group_id);

CREATE INDEX index_deploy_keys_projects_on_deploy_key_id ON public.deploy_keys_projects USING btree (deploy_key_id);

CREATE INDEX index_deploy_keys_projects_on_project_id ON public.deploy_keys_projects USING btree (project_id);

CREATE UNIQUE INDEX index_deploy_tokens_on_token ON public.deploy_tokens USING btree (token);

CREATE INDEX index_deploy_tokens_on_token_and_expires_at_and_id ON public.deploy_tokens USING btree (token, expires_at, id) WHERE (revoked IS FALSE);

CREATE UNIQUE INDEX index_deploy_tokens_on_token_encrypted ON public.deploy_tokens USING btree (token_encrypted);

CREATE UNIQUE INDEX index_deployment_clusters_on_cluster_id_and_deployment_id ON public.deployment_clusters USING btree (cluster_id, deployment_id);

CREATE INDEX index_deployment_merge_requests_on_merge_request_id ON public.deployment_merge_requests USING btree (merge_request_id);

CREATE INDEX index_deployments_on_cluster_id_and_status ON public.deployments USING btree (cluster_id, status);

CREATE INDEX index_deployments_on_created_at ON public.deployments USING btree (created_at);

CREATE INDEX index_deployments_on_deployable_type_and_deployable_id ON public.deployments USING btree (deployable_type, deployable_id);

CREATE INDEX index_deployments_on_environment_id_and_id ON public.deployments USING btree (environment_id, id);

CREATE INDEX index_deployments_on_environment_id_and_iid_and_project_id ON public.deployments USING btree (environment_id, iid, project_id);

CREATE INDEX index_deployments_on_environment_id_and_status ON public.deployments USING btree (environment_id, status);

CREATE INDEX index_deployments_on_id_and_status ON public.deployments USING btree (id, status);

CREATE INDEX index_deployments_on_id_where_cluster_id_present ON public.deployments USING btree (id) WHERE (cluster_id IS NOT NULL);

CREATE INDEX index_deployments_on_project_id_and_id ON public.deployments USING btree (project_id, id DESC);

CREATE UNIQUE INDEX index_deployments_on_project_id_and_iid ON public.deployments USING btree (project_id, iid);

CREATE INDEX index_deployments_on_project_id_and_ref ON public.deployments USING btree (project_id, ref);

CREATE INDEX index_deployments_on_project_id_and_status ON public.deployments USING btree (project_id, status);

CREATE INDEX index_deployments_on_project_id_and_status_and_created_at ON public.deployments USING btree (project_id, status, created_at);

CREATE INDEX index_deployments_on_project_id_and_updated_at_and_id ON public.deployments USING btree (project_id, updated_at DESC, id DESC);

CREATE INDEX index_deployments_on_user_id_and_status_and_created_at ON public.deployments USING btree (user_id, status, created_at);

CREATE INDEX index_description_versions_on_epic_id ON public.description_versions USING btree (epic_id) WHERE (epic_id IS NOT NULL);

CREATE INDEX index_description_versions_on_issue_id ON public.description_versions USING btree (issue_id) WHERE (issue_id IS NOT NULL);

CREATE INDEX index_description_versions_on_merge_request_id ON public.description_versions USING btree (merge_request_id) WHERE (merge_request_id IS NOT NULL);

CREATE UNIQUE INDEX index_design_management_designs_on_issue_id_and_filename ON public.design_management_designs USING btree (issue_id, filename);

CREATE INDEX index_design_management_designs_on_project_id ON public.design_management_designs USING btree (project_id);

CREATE INDEX index_design_management_designs_versions_on_design_id ON public.design_management_designs_versions USING btree (design_id);

CREATE INDEX index_design_management_designs_versions_on_event ON public.design_management_designs_versions USING btree (event);

CREATE INDEX index_design_management_designs_versions_on_version_id ON public.design_management_designs_versions USING btree (version_id);

CREATE INDEX index_design_management_versions_on_author_id ON public.design_management_versions USING btree (author_id) WHERE (author_id IS NOT NULL);

CREATE INDEX index_design_management_versions_on_issue_id ON public.design_management_versions USING btree (issue_id);

CREATE UNIQUE INDEX index_design_management_versions_on_sha_and_issue_id ON public.design_management_versions USING btree (sha, issue_id);

CREATE UNIQUE INDEX index_design_user_mentions_on_note_id ON public.design_user_mentions USING btree (note_id);

CREATE UNIQUE INDEX index_diff_note_positions_on_note_id_and_diff_type ON public.diff_note_positions USING btree (note_id, diff_type);

CREATE INDEX index_draft_notes_on_author_id ON public.draft_notes USING btree (author_id);

CREATE INDEX index_draft_notes_on_discussion_id ON public.draft_notes USING btree (discussion_id);

CREATE INDEX index_draft_notes_on_merge_request_id ON public.draft_notes USING btree (merge_request_id);

CREATE INDEX index_elasticsearch_indexed_namespaces_on_created_at ON public.elasticsearch_indexed_namespaces USING btree (created_at);

CREATE UNIQUE INDEX index_elasticsearch_indexed_namespaces_on_namespace_id ON public.elasticsearch_indexed_namespaces USING btree (namespace_id);

CREATE UNIQUE INDEX index_elasticsearch_indexed_projects_on_project_id ON public.elasticsearch_indexed_projects USING btree (project_id);

CREATE UNIQUE INDEX index_emails_on_confirmation_token ON public.emails USING btree (confirmation_token);

CREATE UNIQUE INDEX index_emails_on_email ON public.emails USING btree (email);

CREATE INDEX index_emails_on_user_id ON public.emails USING btree (user_id);

CREATE INDEX index_enabled_clusters_on_id ON public.clusters USING btree (id) WHERE (enabled = true);

CREATE INDEX index_environments_on_auto_stop_at ON public.environments USING btree (auto_stop_at) WHERE (auto_stop_at IS NOT NULL);

CREATE INDEX index_environments_on_name_varchar_pattern_ops ON public.environments USING btree (name varchar_pattern_ops);

CREATE UNIQUE INDEX index_environments_on_project_id_and_name ON public.environments USING btree (project_id, name);

CREATE UNIQUE INDEX index_environments_on_project_id_and_slug ON public.environments USING btree (project_id, slug);

CREATE INDEX index_environments_on_project_id_state_environment_type ON public.environments USING btree (project_id, state, environment_type);

CREATE INDEX index_environments_on_state_and_auto_stop_at ON public.environments USING btree (state, auto_stop_at) WHERE ((auto_stop_at IS NOT NULL) AND ((state)::text = 'available'::text));

CREATE INDEX index_epic_issues_on_epic_id ON public.epic_issues USING btree (epic_id);

CREATE UNIQUE INDEX index_epic_issues_on_issue_id ON public.epic_issues USING btree (issue_id);

CREATE INDEX index_epic_metrics ON public.epic_metrics USING btree (epic_id);

CREATE UNIQUE INDEX index_epic_user_mentions_on_note_id ON public.epic_user_mentions USING btree (note_id) WHERE (note_id IS NOT NULL);

CREATE INDEX index_epics_on_assignee_id ON public.epics USING btree (assignee_id);

CREATE INDEX index_epics_on_author_id ON public.epics USING btree (author_id);

CREATE INDEX index_epics_on_closed_by_id ON public.epics USING btree (closed_by_id);

CREATE INDEX index_epics_on_confidential ON public.epics USING btree (confidential);

CREATE INDEX index_epics_on_due_date_sourcing_epic_id ON public.epics USING btree (due_date_sourcing_epic_id) WHERE (due_date_sourcing_epic_id IS NOT NULL);

CREATE INDEX index_epics_on_due_date_sourcing_milestone_id ON public.epics USING btree (due_date_sourcing_milestone_id);

CREATE INDEX index_epics_on_end_date ON public.epics USING btree (end_date);

CREATE INDEX index_epics_on_group_id ON public.epics USING btree (group_id);

CREATE UNIQUE INDEX index_epics_on_group_id_and_external_key ON public.epics USING btree (group_id, external_key) WHERE (external_key IS NOT NULL);

CREATE INDEX index_epics_on_group_id_and_iid_varchar_pattern ON public.epics USING btree (group_id, ((iid)::character varying) varchar_pattern_ops);

CREATE INDEX index_epics_on_iid ON public.epics USING btree (iid);

CREATE INDEX index_epics_on_last_edited_by_id ON public.epics USING btree (last_edited_by_id);

CREATE INDEX index_epics_on_lock_version ON public.epics USING btree (lock_version) WHERE (lock_version IS NULL);

CREATE INDEX index_epics_on_parent_id ON public.epics USING btree (parent_id);

CREATE INDEX index_epics_on_start_date ON public.epics USING btree (start_date);

CREATE INDEX index_epics_on_start_date_sourcing_epic_id ON public.epics USING btree (start_date_sourcing_epic_id) WHERE (start_date_sourcing_epic_id IS NOT NULL);

CREATE INDEX index_epics_on_start_date_sourcing_milestone_id ON public.epics USING btree (start_date_sourcing_milestone_id);

CREATE INDEX index_events_on_action ON public.events USING btree (action);

CREATE INDEX index_events_on_author_id_and_created_at ON public.events USING btree (author_id, created_at);

CREATE INDEX index_events_on_author_id_and_created_at_merge_requests ON public.events USING btree (author_id, created_at) WHERE ((target_type)::text = 'MergeRequest'::text);

CREATE INDEX index_events_on_author_id_and_project_id ON public.events USING btree (author_id, project_id);

CREATE INDEX index_events_on_group_id_partial ON public.events USING btree (group_id) WHERE (group_id IS NOT NULL);

CREATE INDEX index_events_on_project_id_and_created_at ON public.events USING btree (project_id, created_at);

CREATE INDEX index_events_on_project_id_and_id ON public.events USING btree (project_id, id);

CREATE INDEX index_events_on_target_type_and_target_id ON public.events USING btree (target_type, target_id);

CREATE INDEX index_evidences_on_release_id ON public.evidences USING btree (release_id);

CREATE INDEX index_expired_and_not_notified_personal_access_tokens ON public.personal_access_tokens USING btree (id, expires_at) WHERE ((impersonation = false) AND (revoked = false) AND (expire_notification_delivered = false));

CREATE UNIQUE INDEX index_external_pull_requests_on_project_and_branches ON public.external_pull_requests USING btree (project_id, source_branch, target_branch);

CREATE UNIQUE INDEX index_feature_flag_scopes_on_flag_id_and_environment_scope ON public.operations_feature_flag_scopes USING btree (feature_flag_id, environment_scope);

CREATE UNIQUE INDEX index_feature_flags_clients_on_project_id_and_token_encrypted ON public.operations_feature_flags_clients USING btree (project_id, token_encrypted);

CREATE UNIQUE INDEX index_feature_gates_on_feature_key_and_key_and_value ON public.feature_gates USING btree (feature_key, key, value);

CREATE UNIQUE INDEX index_features_on_key ON public.features USING btree (key);

CREATE INDEX index_for_resource_group ON public.ci_builds USING btree (resource_group_id, id) WHERE (resource_group_id IS NOT NULL);

CREATE INDEX index_for_status_per_branch_per_project ON public.merge_trains USING btree (target_project_id, target_branch, status);

CREATE INDEX index_fork_network_members_on_fork_network_id ON public.fork_network_members USING btree (fork_network_id);

CREATE INDEX index_fork_network_members_on_forked_from_project_id ON public.fork_network_members USING btree (forked_from_project_id);

CREATE UNIQUE INDEX index_fork_network_members_on_project_id ON public.fork_network_members USING btree (project_id);

CREATE UNIQUE INDEX index_fork_networks_on_root_project_id ON public.fork_networks USING btree (root_project_id);

CREATE INDEX index_geo_event_log_on_cache_invalidation_event_id ON public.geo_event_log USING btree (cache_invalidation_event_id) WHERE (cache_invalidation_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_container_repository_updated_event_id ON public.geo_event_log USING btree (container_repository_updated_event_id);

CREATE INDEX index_geo_event_log_on_geo_event_id ON public.geo_event_log USING btree (geo_event_id) WHERE (geo_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_hashed_storage_attachments_event_id ON public.geo_event_log USING btree (hashed_storage_attachments_event_id) WHERE (hashed_storage_attachments_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_hashed_storage_migrated_event_id ON public.geo_event_log USING btree (hashed_storage_migrated_event_id) WHERE (hashed_storage_migrated_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_job_artifact_deleted_event_id ON public.geo_event_log USING btree (job_artifact_deleted_event_id) WHERE (job_artifact_deleted_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_lfs_object_deleted_event_id ON public.geo_event_log USING btree (lfs_object_deleted_event_id) WHERE (lfs_object_deleted_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_repositories_changed_event_id ON public.geo_event_log USING btree (repositories_changed_event_id) WHERE (repositories_changed_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_repository_created_event_id ON public.geo_event_log USING btree (repository_created_event_id) WHERE (repository_created_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_repository_deleted_event_id ON public.geo_event_log USING btree (repository_deleted_event_id) WHERE (repository_deleted_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_repository_renamed_event_id ON public.geo_event_log USING btree (repository_renamed_event_id) WHERE (repository_renamed_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_repository_updated_event_id ON public.geo_event_log USING btree (repository_updated_event_id) WHERE (repository_updated_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_reset_checksum_event_id ON public.geo_event_log USING btree (reset_checksum_event_id) WHERE (reset_checksum_event_id IS NOT NULL);

CREATE INDEX index_geo_event_log_on_upload_deleted_event_id ON public.geo_event_log USING btree (upload_deleted_event_id) WHERE (upload_deleted_event_id IS NOT NULL);

CREATE INDEX index_geo_hashed_storage_attachments_events_on_project_id ON public.geo_hashed_storage_attachments_events USING btree (project_id);

CREATE INDEX index_geo_hashed_storage_migrated_events_on_project_id ON public.geo_hashed_storage_migrated_events USING btree (project_id);

CREATE INDEX index_geo_job_artifact_deleted_events_on_job_artifact_id ON public.geo_job_artifact_deleted_events USING btree (job_artifact_id);

CREATE INDEX index_geo_lfs_object_deleted_events_on_lfs_object_id ON public.geo_lfs_object_deleted_events USING btree (lfs_object_id);

CREATE INDEX index_geo_node_namespace_links_on_geo_node_id ON public.geo_node_namespace_links USING btree (geo_node_id);

CREATE UNIQUE INDEX index_geo_node_namespace_links_on_geo_node_id_and_namespace_id ON public.geo_node_namespace_links USING btree (geo_node_id, namespace_id);

CREATE INDEX index_geo_node_namespace_links_on_namespace_id ON public.geo_node_namespace_links USING btree (namespace_id);

CREATE UNIQUE INDEX index_geo_node_statuses_on_geo_node_id ON public.geo_node_statuses USING btree (geo_node_id);

CREATE INDEX index_geo_nodes_on_access_key ON public.geo_nodes USING btree (access_key);

CREATE UNIQUE INDEX index_geo_nodes_on_name ON public.geo_nodes USING btree (name);

CREATE INDEX index_geo_nodes_on_primary ON public.geo_nodes USING btree ("primary");

CREATE INDEX index_geo_repositories_changed_events_on_geo_node_id ON public.geo_repositories_changed_events USING btree (geo_node_id);

CREATE INDEX index_geo_repository_created_events_on_project_id ON public.geo_repository_created_events USING btree (project_id);

CREATE INDEX index_geo_repository_deleted_events_on_project_id ON public.geo_repository_deleted_events USING btree (project_id);

CREATE INDEX index_geo_repository_renamed_events_on_project_id ON public.geo_repository_renamed_events USING btree (project_id);

CREATE INDEX index_geo_repository_updated_events_on_project_id ON public.geo_repository_updated_events USING btree (project_id);

CREATE INDEX index_geo_repository_updated_events_on_source ON public.geo_repository_updated_events USING btree (source);

CREATE INDEX index_geo_reset_checksum_events_on_project_id ON public.geo_reset_checksum_events USING btree (project_id);

CREATE INDEX index_geo_upload_deleted_events_on_upload_id ON public.geo_upload_deleted_events USING btree (upload_id);

CREATE INDEX index_gitlab_subscription_histories_on_gitlab_subscription_id ON public.gitlab_subscription_histories USING btree (gitlab_subscription_id);

CREATE INDEX index_gitlab_subscriptions_on_hosted_plan_id ON public.gitlab_subscriptions USING btree (hosted_plan_id);

CREATE UNIQUE INDEX index_gitlab_subscriptions_on_namespace_id ON public.gitlab_subscriptions USING btree (namespace_id);

CREATE UNIQUE INDEX index_gpg_key_subkeys_on_fingerprint ON public.gpg_key_subkeys USING btree (fingerprint);

CREATE INDEX index_gpg_key_subkeys_on_gpg_key_id ON public.gpg_key_subkeys USING btree (gpg_key_id);

CREATE UNIQUE INDEX index_gpg_key_subkeys_on_keyid ON public.gpg_key_subkeys USING btree (keyid);

CREATE UNIQUE INDEX index_gpg_keys_on_fingerprint ON public.gpg_keys USING btree (fingerprint);

CREATE UNIQUE INDEX index_gpg_keys_on_primary_keyid ON public.gpg_keys USING btree (primary_keyid);

CREATE INDEX index_gpg_keys_on_user_id ON public.gpg_keys USING btree (user_id);

CREATE UNIQUE INDEX index_gpg_signatures_on_commit_sha ON public.gpg_signatures USING btree (commit_sha);

CREATE INDEX index_gpg_signatures_on_gpg_key_id ON public.gpg_signatures USING btree (gpg_key_id);

CREATE INDEX index_gpg_signatures_on_gpg_key_primary_keyid ON public.gpg_signatures USING btree (gpg_key_primary_keyid);

CREATE INDEX index_gpg_signatures_on_gpg_key_subkey_id ON public.gpg_signatures USING btree (gpg_key_subkey_id);

CREATE INDEX index_gpg_signatures_on_project_id ON public.gpg_signatures USING btree (project_id);

CREATE INDEX index_grafana_integrations_on_enabled ON public.grafana_integrations USING btree (enabled) WHERE (enabled IS TRUE);

CREATE INDEX index_grafana_integrations_on_project_id ON public.grafana_integrations USING btree (project_id);

CREATE UNIQUE INDEX index_group_custom_attributes_on_group_id_and_key ON public.group_custom_attributes USING btree (group_id, key);

CREATE INDEX index_group_custom_attributes_on_key_and_value ON public.group_custom_attributes USING btree (key, value);

CREATE INDEX index_group_deletion_schedules_on_marked_for_deletion_on ON public.group_deletion_schedules USING btree (marked_for_deletion_on);

CREATE INDEX index_group_deletion_schedules_on_user_id ON public.group_deletion_schedules USING btree (user_id);

CREATE UNIQUE INDEX index_group_deploy_keys_on_fingerprint ON public.group_deploy_keys USING btree (fingerprint);

CREATE INDEX index_group_deploy_keys_on_fingerprint_sha256 ON public.group_deploy_keys USING btree (fingerprint_sha256);

CREATE INDEX index_group_deploy_keys_on_user_id ON public.group_deploy_keys USING btree (user_id);

CREATE INDEX index_group_deploy_tokens_on_deploy_token_id ON public.group_deploy_tokens USING btree (deploy_token_id);

CREATE UNIQUE INDEX index_group_deploy_tokens_on_group_and_deploy_token_ids ON public.group_deploy_tokens USING btree (group_id, deploy_token_id);

CREATE UNIQUE INDEX index_group_group_links_on_shared_group_and_shared_with_group ON public.group_group_links USING btree (shared_group_id, shared_with_group_id);

CREATE INDEX index_group_group_links_on_shared_with_group_id ON public.group_group_links USING btree (shared_with_group_id);

CREATE INDEX index_group_import_states_on_group_id ON public.group_import_states USING btree (group_id);

CREATE UNIQUE INDEX index_group_wiki_repositories_on_disk_path ON public.group_wiki_repositories USING btree (disk_path);

CREATE INDEX index_group_wiki_repositories_on_shard_id ON public.group_wiki_repositories USING btree (shard_id);

CREATE INDEX index_identities_on_saml_provider_id ON public.identities USING btree (saml_provider_id) WHERE (saml_provider_id IS NOT NULL);

CREATE INDEX index_identities_on_user_id ON public.identities USING btree (user_id);

CREATE UNIQUE INDEX index_import_export_uploads_on_group_id ON public.import_export_uploads USING btree (group_id) WHERE (group_id IS NOT NULL);

CREATE INDEX index_import_export_uploads_on_project_id ON public.import_export_uploads USING btree (project_id);

CREATE INDEX index_import_export_uploads_on_updated_at ON public.import_export_uploads USING btree (updated_at);

CREATE INDEX index_import_failures_on_correlation_id_value ON public.import_failures USING btree (correlation_id_value);

CREATE INDEX index_import_failures_on_group_id_not_null ON public.import_failures USING btree (group_id) WHERE (group_id IS NOT NULL);

CREATE INDEX index_import_failures_on_project_id_and_correlation_id_value ON public.import_failures USING btree (project_id, correlation_id_value) WHERE (retry_count = 0);

CREATE INDEX index_import_failures_on_project_id_not_null ON public.import_failures USING btree (project_id) WHERE (project_id IS NOT NULL);

CREATE UNIQUE INDEX index_index_statuses_on_project_id ON public.index_statuses USING btree (project_id);

CREATE INDEX index_insights_on_namespace_id ON public.insights USING btree (namespace_id);

CREATE INDEX index_insights_on_project_id ON public.insights USING btree (project_id);

CREATE INDEX index_internal_ids_on_namespace_id ON public.internal_ids USING btree (namespace_id);

CREATE INDEX index_internal_ids_on_project_id ON public.internal_ids USING btree (project_id);

CREATE UNIQUE INDEX index_internal_ids_on_usage_and_namespace_id ON public.internal_ids USING btree (usage, namespace_id) WHERE (namespace_id IS NOT NULL);

CREATE UNIQUE INDEX index_internal_ids_on_usage_and_project_id ON public.internal_ids USING btree (usage, project_id) WHERE (project_id IS NOT NULL);

CREATE INDEX index_ip_restrictions_on_group_id ON public.ip_restrictions USING btree (group_id);

CREATE UNIQUE INDEX index_issue_assignees_on_issue_id_and_user_id ON public.issue_assignees USING btree (issue_id, user_id);

CREATE INDEX index_issue_assignees_on_user_id ON public.issue_assignees USING btree (user_id);

CREATE INDEX index_issue_links_on_source_id ON public.issue_links USING btree (source_id);

CREATE UNIQUE INDEX index_issue_links_on_source_id_and_target_id ON public.issue_links USING btree (source_id, target_id);

CREATE INDEX index_issue_links_on_target_id ON public.issue_links USING btree (target_id);

CREATE INDEX index_issue_metrics ON public.issue_metrics USING btree (issue_id);

CREATE INDEX index_issue_metrics_on_issue_id_and_timestamps ON public.issue_metrics USING btree (issue_id, first_mentioned_in_commit_at, first_associated_with_milestone_at, first_added_to_board_at);

CREATE INDEX index_issue_tracker_data_on_service_id ON public.issue_tracker_data USING btree (service_id);

CREATE UNIQUE INDEX index_issue_user_mentions_on_note_id ON public.issue_user_mentions USING btree (note_id) WHERE (note_id IS NOT NULL);

CREATE INDEX index_issues_on_author_id ON public.issues USING btree (author_id);

CREATE INDEX index_issues_on_author_id_and_id_and_created_at ON public.issues USING btree (author_id, id, created_at);

CREATE INDEX index_issues_on_closed_by_id ON public.issues USING btree (closed_by_id);

CREATE INDEX index_issues_on_confidential ON public.issues USING btree (confidential);

CREATE INDEX index_issues_on_description_trigram ON public.issues USING gin (description public.gin_trgm_ops);

CREATE INDEX index_issues_on_duplicated_to_id ON public.issues USING btree (duplicated_to_id) WHERE (duplicated_to_id IS NOT NULL);

CREATE INDEX index_issues_on_last_edited_by_id ON public.issues USING btree (last_edited_by_id);

CREATE INDEX index_issues_on_lock_version ON public.issues USING btree (lock_version) WHERE (lock_version IS NULL);

CREATE INDEX index_issues_on_milestone_id ON public.issues USING btree (milestone_id);

CREATE INDEX index_issues_on_moved_to_id ON public.issues USING btree (moved_to_id) WHERE (moved_to_id IS NOT NULL);

CREATE UNIQUE INDEX index_issues_on_project_id_and_external_key ON public.issues USING btree (project_id, external_key) WHERE (external_key IS NOT NULL);

CREATE UNIQUE INDEX index_issues_on_project_id_and_iid ON public.issues USING btree (project_id, iid);

CREATE INDEX index_issues_on_promoted_to_epic_id ON public.issues USING btree (promoted_to_epic_id) WHERE (promoted_to_epic_id IS NOT NULL);

CREATE INDEX index_issues_on_relative_position ON public.issues USING btree (relative_position);

CREATE INDEX index_issues_on_sprint_id ON public.issues USING btree (sprint_id);

CREATE INDEX index_issues_on_title_trigram ON public.issues USING gin (title public.gin_trgm_ops);

CREATE INDEX index_issues_on_updated_at ON public.issues USING btree (updated_at);

CREATE INDEX index_issues_on_updated_by_id ON public.issues USING btree (updated_by_id) WHERE (updated_by_id IS NOT NULL);

CREATE UNIQUE INDEX index_jira_connect_installations_on_client_key ON public.jira_connect_installations USING btree (client_key);

CREATE INDEX index_jira_connect_subscriptions_on_namespace_id ON public.jira_connect_subscriptions USING btree (namespace_id);

CREATE INDEX index_jira_imports_on_label_id ON public.jira_imports USING btree (label_id);

CREATE INDEX index_jira_imports_on_project_id_and_jira_project_key ON public.jira_imports USING btree (project_id, jira_project_key);

CREATE INDEX index_jira_imports_on_user_id ON public.jira_imports USING btree (user_id);

CREATE INDEX index_jira_tracker_data_on_service_id ON public.jira_tracker_data USING btree (service_id);

CREATE UNIQUE INDEX index_keys_on_fingerprint ON public.keys USING btree (fingerprint);

CREATE INDEX index_keys_on_fingerprint_sha256 ON public.keys USING btree (fingerprint_sha256);

CREATE INDEX index_keys_on_id_and_ldap_key_type ON public.keys USING btree (id) WHERE ((type)::text = 'LDAPKey'::text);

CREATE INDEX index_keys_on_last_used_at ON public.keys USING btree (last_used_at DESC NULLS LAST);

CREATE INDEX index_keys_on_user_id ON public.keys USING btree (user_id);

CREATE UNIQUE INDEX index_kubernetes_namespaces_on_cluster_project_environment_id ON public.clusters_kubernetes_namespaces USING btree (cluster_id, project_id, environment_id);

CREATE INDEX index_label_links_on_label_id ON public.label_links USING btree (label_id);

CREATE INDEX index_label_links_on_target_id_and_target_type ON public.label_links USING btree (target_id, target_type);

CREATE INDEX index_label_priorities_on_label_id ON public.label_priorities USING btree (label_id);

CREATE INDEX index_label_priorities_on_priority ON public.label_priorities USING btree (priority);

CREATE UNIQUE INDEX index_label_priorities_on_project_id_and_label_id ON public.label_priorities USING btree (project_id, label_id);

CREATE UNIQUE INDEX index_labels_on_group_id_and_project_id_and_title ON public.labels USING btree (group_id, project_id, title);

CREATE INDEX index_labels_on_group_id_and_title ON public.labels USING btree (group_id, title) WHERE (project_id = NULL::integer);

CREATE INDEX index_labels_on_project_id ON public.labels USING btree (project_id);

CREATE INDEX index_labels_on_project_id_and_title ON public.labels USING btree (project_id, title) WHERE (group_id = NULL::integer);

CREATE INDEX index_labels_on_template ON public.labels USING btree (template) WHERE template;

CREATE INDEX index_labels_on_title ON public.labels USING btree (title);

CREATE INDEX index_labels_on_type_and_project_id ON public.labels USING btree (type, project_id);

CREATE UNIQUE INDEX index_lfs_file_locks_on_project_id_and_path ON public.lfs_file_locks USING btree (project_id, path);

CREATE INDEX index_lfs_file_locks_on_user_id ON public.lfs_file_locks USING btree (user_id);

CREATE INDEX index_lfs_objects_file_store_is_null ON public.lfs_objects USING btree (id) WHERE (file_store IS NULL);

CREATE INDEX index_lfs_objects_on_file_store ON public.lfs_objects USING btree (file_store);

CREATE UNIQUE INDEX index_lfs_objects_on_oid ON public.lfs_objects USING btree (oid);

CREATE INDEX index_lfs_objects_projects_on_lfs_object_id ON public.lfs_objects_projects USING btree (lfs_object_id);

CREATE INDEX index_lfs_objects_projects_on_project_id_and_lfs_object_id ON public.lfs_objects_projects USING btree (project_id, lfs_object_id);

CREATE INDEX index_list_user_preferences_on_list_id ON public.list_user_preferences USING btree (list_id);

CREATE INDEX index_list_user_preferences_on_user_id ON public.list_user_preferences USING btree (user_id);

CREATE UNIQUE INDEX index_list_user_preferences_on_user_id_and_list_id ON public.list_user_preferences USING btree (user_id, list_id);

CREATE UNIQUE INDEX index_lists_on_board_id_and_label_id ON public.lists USING btree (board_id, label_id);

CREATE INDEX index_lists_on_label_id ON public.lists USING btree (label_id);

CREATE INDEX index_lists_on_list_type ON public.lists USING btree (list_type);

CREATE INDEX index_lists_on_milestone_id ON public.lists USING btree (milestone_id);

CREATE INDEX index_lists_on_user_id ON public.lists USING btree (user_id);

CREATE INDEX index_members_on_access_level ON public.members USING btree (access_level);

CREATE INDEX index_members_on_expires_at ON public.members USING btree (expires_at);

CREATE INDEX index_members_on_invite_email ON public.members USING btree (invite_email);

CREATE UNIQUE INDEX index_members_on_invite_token ON public.members USING btree (invite_token);

CREATE INDEX index_members_on_requested_at ON public.members USING btree (requested_at);

CREATE INDEX index_members_on_source_id_and_source_type ON public.members USING btree (source_id, source_type);

CREATE INDEX index_members_on_user_id ON public.members USING btree (user_id);

CREATE INDEX index_members_on_user_id_created_at ON public.members USING btree (user_id, created_at) WHERE ((ldap = true) AND ((type)::text = 'GroupMember'::text) AND ((source_type)::text = 'Namespace'::text));

CREATE INDEX index_merge_request_assignees_on_merge_request_id ON public.merge_request_assignees USING btree (merge_request_id);

CREATE UNIQUE INDEX index_merge_request_assignees_on_merge_request_id_and_user_id ON public.merge_request_assignees USING btree (merge_request_id, user_id);

CREATE INDEX index_merge_request_assignees_on_user_id ON public.merge_request_assignees USING btree (user_id);

CREATE INDEX index_merge_request_blocks_on_blocked_merge_request_id ON public.merge_request_blocks USING btree (blocked_merge_request_id);

CREATE UNIQUE INDEX index_merge_request_diff_commits_on_mr_diff_id_and_order ON public.merge_request_diff_commits USING btree (merge_request_diff_id, relative_order);

CREATE INDEX index_merge_request_diff_commits_on_sha ON public.merge_request_diff_commits USING btree (sha);

CREATE UNIQUE INDEX index_merge_request_diff_files_on_mr_diff_id_and_order ON public.merge_request_diff_files USING btree (merge_request_diff_id, relative_order);

CREATE INDEX index_merge_request_diffs_on_merge_request_id_and_id ON public.merge_request_diffs USING btree (merge_request_id, id);

CREATE INDEX index_merge_request_diffs_on_merge_request_id_and_id_partial ON public.merge_request_diffs USING btree (merge_request_id, id) WHERE ((NOT stored_externally) OR (stored_externally IS NULL));

CREATE INDEX index_merge_request_metrics ON public.merge_request_metrics USING btree (merge_request_id);

CREATE INDEX index_merge_request_metrics_on_first_deployed_to_production_at ON public.merge_request_metrics USING btree (first_deployed_to_production_at);

CREATE INDEX index_merge_request_metrics_on_latest_closed_at ON public.merge_request_metrics USING btree (latest_closed_at) WHERE (latest_closed_at IS NOT NULL);

CREATE INDEX index_merge_request_metrics_on_latest_closed_by_id ON public.merge_request_metrics USING btree (latest_closed_by_id);

CREATE INDEX index_merge_request_metrics_on_merge_request_id_and_merged_at ON public.merge_request_metrics USING btree (merge_request_id, merged_at) WHERE (merged_at IS NOT NULL);

CREATE INDEX index_merge_request_metrics_on_merged_at ON public.merge_request_metrics USING btree (merged_at);

CREATE INDEX index_merge_request_metrics_on_merged_by_id ON public.merge_request_metrics USING btree (merged_by_id);

CREATE INDEX index_merge_request_metrics_on_pipeline_id ON public.merge_request_metrics USING btree (pipeline_id);

CREATE UNIQUE INDEX index_merge_request_user_mentions_on_note_id ON public.merge_request_user_mentions USING btree (note_id) WHERE (note_id IS NOT NULL);

CREATE INDEX index_merge_requests_closing_issues_on_issue_id ON public.merge_requests_closing_issues USING btree (issue_id);

CREATE INDEX index_merge_requests_closing_issues_on_merge_request_id ON public.merge_requests_closing_issues USING btree (merge_request_id);

CREATE INDEX index_merge_requests_on_assignee_id ON public.merge_requests USING btree (assignee_id);

CREATE INDEX index_merge_requests_on_author_id ON public.merge_requests USING btree (author_id);

CREATE INDEX index_merge_requests_on_created_at ON public.merge_requests USING btree (created_at);

CREATE INDEX index_merge_requests_on_description_trigram ON public.merge_requests USING gin (description public.gin_trgm_ops);

CREATE INDEX index_merge_requests_on_head_pipeline_id ON public.merge_requests USING btree (head_pipeline_id);

CREATE INDEX index_merge_requests_on_latest_merge_request_diff_id ON public.merge_requests USING btree (latest_merge_request_diff_id);

CREATE INDEX index_merge_requests_on_lock_version ON public.merge_requests USING btree (lock_version) WHERE (lock_version IS NULL);

CREATE INDEX index_merge_requests_on_merge_user_id ON public.merge_requests USING btree (merge_user_id) WHERE (merge_user_id IS NOT NULL);

CREATE INDEX index_merge_requests_on_milestone_id ON public.merge_requests USING btree (milestone_id);

CREATE INDEX index_merge_requests_on_source_branch ON public.merge_requests USING btree (source_branch);

CREATE INDEX index_merge_requests_on_source_project_id_and_source_branch ON public.merge_requests USING btree (source_project_id, source_branch);

CREATE INDEX index_merge_requests_on_sprint_id ON public.merge_requests USING btree (sprint_id);

CREATE INDEX index_merge_requests_on_target_branch ON public.merge_requests USING btree (target_branch);

CREATE UNIQUE INDEX index_merge_requests_on_target_project_id_and_iid ON public.merge_requests USING btree (target_project_id, iid);

CREATE INDEX index_merge_requests_on_target_project_id_and_target_branch ON public.merge_requests USING btree (target_project_id, target_branch) WHERE ((state_id = 1) AND (merge_when_pipeline_succeeds = true));

CREATE INDEX index_merge_requests_on_title ON public.merge_requests USING btree (title);

CREATE INDEX index_merge_requests_on_title_trigram ON public.merge_requests USING gin (title public.gin_trgm_ops);

CREATE INDEX index_merge_requests_on_tp_id_and_merge_commit_sha_and_id ON public.merge_requests USING btree (target_project_id, merge_commit_sha, id);

CREATE INDEX index_merge_requests_on_updated_by_id ON public.merge_requests USING btree (updated_by_id) WHERE (updated_by_id IS NOT NULL);

CREATE INDEX index_merge_requests_target_project_id_created_at ON public.merge_requests USING btree (target_project_id, created_at);

CREATE UNIQUE INDEX index_merge_trains_on_merge_request_id ON public.merge_trains USING btree (merge_request_id);

CREATE INDEX index_merge_trains_on_pipeline_id ON public.merge_trains USING btree (pipeline_id);

CREATE INDEX index_merge_trains_on_user_id ON public.merge_trains USING btree (user_id);

CREATE INDEX index_metrics_dashboard_annotations_on_cluster_id_and_3_columns ON public.metrics_dashboard_annotations USING btree (cluster_id, dashboard_path, starting_at, ending_at) WHERE (cluster_id IS NOT NULL);

CREATE INDEX index_metrics_dashboard_annotations_on_environment_id_and_3_col ON public.metrics_dashboard_annotations USING btree (environment_id, dashboard_path, starting_at, ending_at) WHERE (environment_id IS NOT NULL);

CREATE INDEX index_metrics_dashboard_annotations_on_timespan_end ON public.metrics_dashboard_annotations USING btree (COALESCE(ending_at, starting_at));

CREATE INDEX index_metrics_users_starred_dashboards_on_project_id ON public.metrics_users_starred_dashboards USING btree (project_id);

CREATE INDEX index_milestone_releases_on_release_id ON public.milestone_releases USING btree (release_id);

CREATE INDEX index_milestones_on_description_trigram ON public.milestones USING gin (description public.gin_trgm_ops);

CREATE INDEX index_milestones_on_due_date ON public.milestones USING btree (due_date);

CREATE INDEX index_milestones_on_group_id ON public.milestones USING btree (group_id);

CREATE UNIQUE INDEX index_milestones_on_project_id_and_iid ON public.milestones USING btree (project_id, iid);

CREATE INDEX index_milestones_on_title ON public.milestones USING btree (title);

CREATE INDEX index_milestones_on_title_trigram ON public.milestones USING gin (title public.gin_trgm_ops);

CREATE UNIQUE INDEX index_miletone_releases_on_milestone_and_release ON public.milestone_releases USING btree (milestone_id, release_id);

CREATE INDEX index_mirror_data_on_next_execution_and_retry_count ON public.project_mirror_data USING btree (next_execution_timestamp, retry_count);

CREATE UNIQUE INDEX index_mr_blocks_on_blocking_and_blocked_mr_ids ON public.merge_request_blocks USING btree (blocking_merge_request_id, blocked_merge_request_id);

CREATE UNIQUE INDEX index_mr_context_commits_on_merge_request_id_and_sha ON public.merge_request_context_commits USING btree (merge_request_id, sha);

CREATE UNIQUE INDEX index_namespace_aggregation_schedules_on_namespace_id ON public.namespace_aggregation_schedules USING btree (namespace_id);

CREATE UNIQUE INDEX index_namespace_root_storage_statistics_on_namespace_id ON public.namespace_root_storage_statistics USING btree (namespace_id);

CREATE UNIQUE INDEX index_namespace_statistics_on_namespace_id ON public.namespace_statistics USING btree (namespace_id);

CREATE INDEX index_namespaces_on_created_at ON public.namespaces USING btree (created_at);

CREATE INDEX index_namespaces_on_custom_project_templates_group_id_and_type ON public.namespaces USING btree (custom_project_templates_group_id, type) WHERE (custom_project_templates_group_id IS NOT NULL);

CREATE INDEX index_namespaces_on_file_template_project_id ON public.namespaces USING btree (file_template_project_id);

CREATE INDEX index_namespaces_on_ldap_sync_last_successful_update_at ON public.namespaces USING btree (ldap_sync_last_successful_update_at);

CREATE INDEX index_namespaces_on_ldap_sync_last_update_at ON public.namespaces USING btree (ldap_sync_last_update_at);

CREATE UNIQUE INDEX index_namespaces_on_name_and_parent_id ON public.namespaces USING btree (name, parent_id);

CREATE INDEX index_namespaces_on_name_trigram ON public.namespaces USING gin (name public.gin_trgm_ops);

CREATE INDEX index_namespaces_on_owner_id ON public.namespaces USING btree (owner_id);

CREATE UNIQUE INDEX index_namespaces_on_parent_id_and_id ON public.namespaces USING btree (parent_id, id);

CREATE INDEX index_namespaces_on_path ON public.namespaces USING btree (path);

CREATE INDEX index_namespaces_on_path_trigram ON public.namespaces USING gin (path public.gin_trgm_ops);

CREATE UNIQUE INDEX index_namespaces_on_push_rule_id ON public.namespaces USING btree (push_rule_id);

CREATE INDEX index_namespaces_on_require_two_factor_authentication ON public.namespaces USING btree (require_two_factor_authentication);

CREATE UNIQUE INDEX index_namespaces_on_runners_token ON public.namespaces USING btree (runners_token);

CREATE UNIQUE INDEX index_namespaces_on_runners_token_encrypted ON public.namespaces USING btree (runners_token_encrypted);

CREATE INDEX index_namespaces_on_shared_and_extra_runners_minutes_limit ON public.namespaces USING btree (shared_runners_minutes_limit, extra_shared_runners_minutes_limit);

CREATE INDEX index_namespaces_on_type_partial ON public.namespaces USING btree (type) WHERE (type IS NOT NULL);

CREATE INDEX index_non_requested_project_members_on_source_id_and_type ON public.members USING btree (source_id, source_type) WHERE ((requested_at IS NULL) AND ((type)::text = 'ProjectMember'::text));

CREATE UNIQUE INDEX index_note_diff_files_on_diff_note_id ON public.note_diff_files USING btree (diff_note_id);

CREATE INDEX index_notes_on_author_id_and_created_at_and_id ON public.notes USING btree (author_id, created_at, id);

CREATE INDEX index_notes_on_commit_id ON public.notes USING btree (commit_id);

CREATE INDEX index_notes_on_created_at ON public.notes USING btree (created_at);

CREATE INDEX index_notes_on_discussion_id ON public.notes USING btree (discussion_id);

CREATE INDEX index_notes_on_line_code ON public.notes USING btree (line_code);

CREATE INDEX index_notes_on_note_trigram ON public.notes USING gin (note public.gin_trgm_ops);

CREATE INDEX index_notes_on_noteable_id_and_noteable_type ON public.notes USING btree (noteable_id, noteable_type);

CREATE INDEX index_notes_on_project_id_and_id_and_system_false ON public.notes USING btree (project_id, id) WHERE (NOT system);

CREATE INDEX index_notes_on_project_id_and_noteable_type ON public.notes USING btree (project_id, noteable_type);

CREATE INDEX index_notes_on_review_id ON public.notes USING btree (review_id);

CREATE INDEX index_notification_settings_on_source_id_and_source_type ON public.notification_settings USING btree (source_id, source_type);

CREATE INDEX index_notification_settings_on_user_id ON public.notification_settings USING btree (user_id);

CREATE UNIQUE INDEX index_notifications_on_user_id_and_source_id_and_source_type ON public.notification_settings USING btree (user_id, source_id, source_type);

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);

CREATE INDEX index_oauth_applications_on_owner_id_and_owner_type ON public.oauth_applications USING btree (owner_id, owner_type);

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);

CREATE INDEX index_oauth_openid_requests_on_access_grant_id ON public.oauth_openid_requests USING btree (access_grant_id);

CREATE UNIQUE INDEX index_on_deploy_keys_id_and_type_and_public ON public.keys USING btree (id, type) WHERE (public = true);

CREATE INDEX index_on_id_partial_with_legacy_storage ON public.projects USING btree (id) WHERE ((storage_version < 2) OR (storage_version IS NULL));

CREATE INDEX index_on_identities_lower_extern_uid_and_provider ON public.identities USING btree (lower((extern_uid)::text), provider);

CREATE INDEX index_on_users_name_lower ON public.users USING btree (lower((name)::text));

CREATE INDEX index_open_project_tracker_data_on_service_id ON public.open_project_tracker_data USING btree (service_id);

CREATE INDEX index_operations_feature_flags_issues_on_issue_id ON public.operations_feature_flags_issues USING btree (issue_id);

CREATE UNIQUE INDEX index_operations_feature_flags_on_project_id_and_iid ON public.operations_feature_flags USING btree (project_id, iid);

CREATE UNIQUE INDEX index_operations_feature_flags_on_project_id_and_name ON public.operations_feature_flags USING btree (project_id, name);

CREATE UNIQUE INDEX index_operations_scopes_on_strategy_id_and_environment_scope ON public.operations_scopes USING btree (strategy_id, environment_scope);

CREATE INDEX index_operations_strategies_on_feature_flag_id ON public.operations_strategies USING btree (feature_flag_id);

CREATE INDEX index_operations_strategies_user_lists_on_user_list_id ON public.operations_strategies_user_lists USING btree (user_list_id);

CREATE UNIQUE INDEX index_operations_user_lists_on_project_id_and_iid ON public.operations_user_lists USING btree (project_id, iid);

CREATE UNIQUE INDEX index_operations_user_lists_on_project_id_and_name ON public.operations_user_lists USING btree (project_id, name);

CREATE UNIQUE INDEX index_ops_feature_flags_issues_on_feature_flag_id_and_issue_id ON public.operations_feature_flags_issues USING btree (feature_flag_id, issue_id);

CREATE UNIQUE INDEX index_ops_strategies_user_lists_on_strategy_id_and_user_list_id ON public.operations_strategies_user_lists USING btree (strategy_id, user_list_id);

CREATE UNIQUE INDEX index_packages_build_infos_on_package_id ON public.packages_build_infos USING btree (package_id);

CREATE INDEX index_packages_build_infos_on_pipeline_id ON public.packages_build_infos USING btree (pipeline_id);

CREATE UNIQUE INDEX index_packages_conan_file_metadata_on_package_file_id ON public.packages_conan_file_metadata USING btree (package_file_id);

CREATE UNIQUE INDEX index_packages_conan_metadata_on_package_id_username_channel ON public.packages_conan_metadata USING btree (package_id, package_username, package_channel);

CREATE UNIQUE INDEX index_packages_dependencies_on_name_and_version_pattern ON public.packages_dependencies USING btree (name, version_pattern);

CREATE INDEX index_packages_dependency_links_on_dependency_id ON public.packages_dependency_links USING btree (dependency_id);

CREATE INDEX index_packages_maven_metadata_on_package_id_and_path ON public.packages_maven_metadata USING btree (package_id, path);

CREATE INDEX index_packages_nuget_dl_metadata_on_dependency_link_id ON public.packages_nuget_dependency_link_metadata USING btree (dependency_link_id);

CREATE INDEX index_packages_package_files_on_package_id_and_file_name ON public.packages_package_files USING btree (package_id, file_name);

CREATE INDEX index_packages_packages_on_name_trigram ON public.packages_packages USING gin (name public.gin_trgm_ops);

CREATE INDEX index_packages_packages_on_project_id_and_created_at ON public.packages_packages USING btree (project_id, created_at);

CREATE INDEX index_packages_packages_on_project_id_and_package_type ON public.packages_packages USING btree (project_id, package_type);

CREATE INDEX index_packages_packages_on_project_id_and_version ON public.packages_packages USING btree (project_id, version);

CREATE INDEX index_packages_project_id_name_partial_for_nuget ON public.packages_packages USING btree (project_id, name) WHERE (((name)::text <> 'NuGet.Temporary.Package'::text) AND (version IS NOT NULL) AND (package_type = 4));

CREATE INDEX index_packages_tags_on_package_id ON public.packages_tags USING btree (package_id);

CREATE INDEX index_packages_tags_on_package_id_and_updated_at ON public.packages_tags USING btree (package_id, updated_at DESC);

CREATE INDEX index_pages_domain_acme_orders_on_challenge_token ON public.pages_domain_acme_orders USING btree (challenge_token);

CREATE INDEX index_pages_domain_acme_orders_on_pages_domain_id ON public.pages_domain_acme_orders USING btree (pages_domain_id);

CREATE INDEX index_pages_domains_need_auto_ssl_renewal_user_provided ON public.pages_domains USING btree (id) WHERE ((auto_ssl_enabled = true) AND (auto_ssl_failed = false) AND (certificate_source = 0));

CREATE INDEX index_pages_domains_need_auto_ssl_renewal_valid_not_after ON public.pages_domains USING btree (certificate_valid_not_after) WHERE ((auto_ssl_enabled = true) AND (auto_ssl_failed = false));

CREATE UNIQUE INDEX index_pages_domains_on_domain_and_wildcard ON public.pages_domains USING btree (domain, wildcard);

CREATE INDEX index_pages_domains_on_domain_lowercase ON public.pages_domains USING btree (lower((domain)::text));

CREATE INDEX index_pages_domains_on_project_id ON public.pages_domains USING btree (project_id);

CREATE INDEX index_pages_domains_on_project_id_and_enabled_until ON public.pages_domains USING btree (project_id, enabled_until);

CREATE INDEX index_pages_domains_on_remove_at ON public.pages_domains USING btree (remove_at);

CREATE INDEX index_pages_domains_on_scope ON public.pages_domains USING btree (scope);

CREATE INDEX index_pages_domains_on_usage ON public.pages_domains USING btree (usage);

CREATE INDEX index_pages_domains_on_verified_at ON public.pages_domains USING btree (verified_at);

CREATE INDEX index_pages_domains_on_verified_at_and_enabled_until ON public.pages_domains USING btree (verified_at, enabled_until);

CREATE INDEX index_pages_domains_on_wildcard ON public.pages_domains USING btree (wildcard);

CREATE UNIQUE INDEX index_partitioned_foreign_keys_unique_index ON public.partitioned_foreign_keys USING btree (to_table, from_table, from_column);

CREATE INDEX index_pat_on_user_id_and_expires_at ON public.personal_access_tokens USING btree (user_id, expires_at);

CREATE INDEX index_path_locks_on_path ON public.path_locks USING btree (path);

CREATE INDEX index_path_locks_on_project_id ON public.path_locks USING btree (project_id);

CREATE INDEX index_path_locks_on_user_id ON public.path_locks USING btree (user_id);

CREATE UNIQUE INDEX index_personal_access_tokens_on_token_digest ON public.personal_access_tokens USING btree (token_digest);

CREATE INDEX index_personal_access_tokens_on_user_id ON public.personal_access_tokens USING btree (user_id);

CREATE UNIQUE INDEX index_plan_limits_on_plan_id ON public.plan_limits USING btree (plan_id);

CREATE UNIQUE INDEX index_plans_on_name ON public.plans USING btree (name);

CREATE UNIQUE INDEX index_pool_repositories_on_disk_path ON public.pool_repositories USING btree (disk_path);

CREATE INDEX index_pool_repositories_on_shard_id ON public.pool_repositories USING btree (shard_id);

CREATE UNIQUE INDEX index_pool_repositories_on_source_project_id_and_shard_id ON public.pool_repositories USING btree (source_project_id, shard_id);

CREATE UNIQUE INDEX index_programming_languages_on_name ON public.programming_languages USING btree (name);

CREATE UNIQUE INDEX index_project_aliases_on_name ON public.project_aliases USING btree (name);

CREATE INDEX index_project_aliases_on_project_id ON public.project_aliases USING btree (project_id);

CREATE INDEX index_project_authorizations_on_project_id ON public.project_authorizations USING btree (project_id);

CREATE UNIQUE INDEX index_project_authorizations_on_user_id_project_id_access_level ON public.project_authorizations USING btree (user_id, project_id, access_level);

CREATE UNIQUE INDEX index_project_auto_devops_on_project_id ON public.project_auto_devops USING btree (project_id);

CREATE UNIQUE INDEX index_project_ci_cd_settings_on_project_id ON public.project_ci_cd_settings USING btree (project_id);

CREATE INDEX index_project_compliance_framework_settings_on_project_id ON public.project_compliance_framework_settings USING btree (project_id);

CREATE INDEX index_project_custom_attributes_on_key_and_value ON public.project_custom_attributes USING btree (key, value);

CREATE UNIQUE INDEX index_project_custom_attributes_on_project_id_and_key ON public.project_custom_attributes USING btree (project_id, key);

CREATE UNIQUE INDEX index_project_daily_statistics_on_project_id_and_date ON public.project_daily_statistics USING btree (project_id, date DESC);

CREATE INDEX index_project_deploy_tokens_on_deploy_token_id ON public.project_deploy_tokens USING btree (deploy_token_id);

CREATE UNIQUE INDEX index_project_deploy_tokens_on_project_id_and_deploy_token_id ON public.project_deploy_tokens USING btree (project_id, deploy_token_id);

CREATE UNIQUE INDEX index_project_export_jobs_on_jid ON public.project_export_jobs USING btree (jid);

CREATE INDEX index_project_export_jobs_on_project_id_and_jid ON public.project_export_jobs USING btree (project_id, jid);

CREATE INDEX index_project_export_jobs_on_project_id_and_status ON public.project_export_jobs USING btree (project_id, status);

CREATE INDEX index_project_export_jobs_on_status ON public.project_export_jobs USING btree (status);

CREATE INDEX index_project_feature_usages_on_project_id ON public.project_feature_usages USING btree (project_id);

CREATE UNIQUE INDEX index_project_features_on_project_id ON public.project_features USING btree (project_id);

CREATE INDEX index_project_features_on_project_id_bal_20 ON public.project_features USING btree (project_id) WHERE (builds_access_level = 20);

CREATE INDEX index_project_features_on_project_id_ral_20 ON public.project_features USING btree (project_id) WHERE (repository_access_level = 20);

CREATE INDEX index_project_group_links_on_group_id ON public.project_group_links USING btree (group_id);

CREATE INDEX index_project_group_links_on_project_id ON public.project_group_links USING btree (project_id);

CREATE INDEX index_project_import_data_on_project_id ON public.project_import_data USING btree (project_id);

CREATE INDEX index_project_mirror_data_on_last_successful_update_at ON public.project_mirror_data USING btree (last_successful_update_at);

CREATE INDEX index_project_mirror_data_on_last_update_at_and_retry_count ON public.project_mirror_data USING btree (last_update_at, retry_count);

CREATE UNIQUE INDEX index_project_mirror_data_on_project_id ON public.project_mirror_data USING btree (project_id);

CREATE INDEX index_project_mirror_data_on_status ON public.project_mirror_data USING btree (status);

CREATE UNIQUE INDEX index_project_pages_metadata_on_project_id ON public.project_pages_metadata USING btree (project_id);

CREATE INDEX index_project_pages_metadata_on_project_id_and_deployed_is_true ON public.project_pages_metadata USING btree (project_id) WHERE (deployed = true);

CREATE UNIQUE INDEX index_project_repositories_on_disk_path ON public.project_repositories USING btree (disk_path);

CREATE UNIQUE INDEX index_project_repositories_on_project_id ON public.project_repositories USING btree (project_id);

CREATE INDEX index_project_repositories_on_shard_id ON public.project_repositories USING btree (shard_id);

CREATE UNIQUE INDEX index_project_repository_states_on_project_id ON public.project_repository_states USING btree (project_id);

CREATE INDEX index_project_repository_storage_moves_on_project_id ON public.project_repository_storage_moves USING btree (project_id);

CREATE UNIQUE INDEX index_project_settings_on_push_rule_id ON public.project_settings USING btree (push_rule_id);

CREATE INDEX index_project_statistics_on_namespace_id ON public.project_statistics USING btree (namespace_id);

CREATE UNIQUE INDEX index_project_statistics_on_project_id ON public.project_statistics USING btree (project_id);

CREATE UNIQUE INDEX index_project_tracing_settings_on_project_id ON public.project_tracing_settings USING btree (project_id);

CREATE INDEX index_projects_api_created_at_id_desc ON public.projects USING btree (created_at, id DESC);

CREATE INDEX index_projects_api_created_at_id_for_archived ON public.projects USING btree (created_at, id) WHERE ((archived = true) AND (pending_delete = false));

CREATE INDEX index_projects_api_created_at_id_for_archived_vis20 ON public.projects USING btree (created_at, id) WHERE ((archived = true) AND (visibility_level = 20) AND (pending_delete = false));

CREATE INDEX index_projects_api_created_at_id_for_vis10 ON public.projects USING btree (created_at, id) WHERE ((visibility_level = 10) AND (pending_delete = false));

CREATE INDEX index_projects_api_last_activity_at_id_desc ON public.projects USING btree (last_activity_at, id DESC);

CREATE INDEX index_projects_api_name_id_desc ON public.projects USING btree (name, id DESC);

CREATE INDEX index_projects_api_path_id_desc ON public.projects USING btree (path, id DESC);

CREATE INDEX index_projects_api_updated_at_id_desc ON public.projects USING btree (updated_at, id DESC);

CREATE INDEX index_projects_api_vis20_created_at ON public.projects USING btree (created_at, id) WHERE (visibility_level = 20);

CREATE INDEX index_projects_api_vis20_last_activity_at ON public.projects USING btree (last_activity_at, id) WHERE (visibility_level = 20);

CREATE INDEX index_projects_api_vis20_name ON public.projects USING btree (name, id) WHERE (visibility_level = 20);

CREATE INDEX index_projects_api_vis20_path ON public.projects USING btree (path, id) WHERE (visibility_level = 20);

CREATE INDEX index_projects_api_vis20_updated_at ON public.projects USING btree (updated_at, id) WHERE (visibility_level = 20);

CREATE INDEX index_projects_on_created_at_and_id ON public.projects USING btree (created_at, id);

CREATE INDEX index_projects_on_creator_id_and_created_at_and_id ON public.projects USING btree (creator_id, created_at, id);

CREATE INDEX index_projects_on_creator_id_and_id ON public.projects USING btree (creator_id, id);

CREATE INDEX index_projects_on_description_trigram ON public.projects USING gin (description public.gin_trgm_ops);

CREATE INDEX index_projects_on_id_and_archived_and_pending_delete ON public.projects USING btree (id) WHERE ((archived = false) AND (pending_delete = false));

CREATE UNIQUE INDEX index_projects_on_id_partial_for_visibility ON public.projects USING btree (id) WHERE (visibility_level = ANY (ARRAY[10, 20]));

CREATE INDEX index_projects_on_id_service_desk_enabled ON public.projects USING btree (id) WHERE (service_desk_enabled = true);

CREATE INDEX index_projects_on_last_activity_at_and_id ON public.projects USING btree (last_activity_at, id);

CREATE INDEX index_projects_on_last_repository_check_at ON public.projects USING btree (last_repository_check_at) WHERE (last_repository_check_at IS NOT NULL);

CREATE INDEX index_projects_on_last_repository_check_failed ON public.projects USING btree (last_repository_check_failed);

CREATE INDEX index_projects_on_last_repository_updated_at ON public.projects USING btree (last_repository_updated_at);

CREATE INDEX index_projects_on_lower_name ON public.projects USING btree (lower((name)::text));

CREATE INDEX index_projects_on_marked_for_deletion_at ON public.projects USING btree (marked_for_deletion_at) WHERE (marked_for_deletion_at IS NOT NULL);

CREATE INDEX index_projects_on_marked_for_deletion_by_user_id ON public.projects USING btree (marked_for_deletion_by_user_id) WHERE (marked_for_deletion_by_user_id IS NOT NULL);

CREATE INDEX index_projects_on_mirror_creator_id_created_at ON public.projects USING btree (creator_id, created_at) WHERE ((mirror = true) AND (mirror_trigger_builds = true));

CREATE INDEX index_projects_on_mirror_id_where_mirror_and_trigger_builds ON public.projects USING btree (id) WHERE ((mirror = true) AND (mirror_trigger_builds = true));

CREATE INDEX index_projects_on_mirror_last_successful_update_at ON public.projects USING btree (mirror_last_successful_update_at);

CREATE INDEX index_projects_on_mirror_user_id ON public.projects USING btree (mirror_user_id);

CREATE INDEX index_projects_on_name_and_id ON public.projects USING btree (name, id);

CREATE INDEX index_projects_on_name_trigram ON public.projects USING gin (name public.gin_trgm_ops);

CREATE INDEX index_projects_on_namespace_id_and_id ON public.projects USING btree (namespace_id, id);

CREATE INDEX index_projects_on_path_and_id ON public.projects USING btree (path, id);

CREATE INDEX index_projects_on_path_trigram ON public.projects USING gin (path public.gin_trgm_ops);

CREATE INDEX index_projects_on_pending_delete ON public.projects USING btree (pending_delete);

CREATE INDEX index_projects_on_pool_repository_id ON public.projects USING btree (pool_repository_id) WHERE (pool_repository_id IS NOT NULL);

CREATE INDEX index_projects_on_repository_storage ON public.projects USING btree (repository_storage);

CREATE INDEX index_projects_on_runners_token ON public.projects USING btree (runners_token);

CREATE INDEX index_projects_on_runners_token_encrypted ON public.projects USING btree (runners_token_encrypted);

CREATE INDEX index_projects_on_star_count ON public.projects USING btree (star_count);

CREATE INDEX index_projects_on_updated_at_and_id ON public.projects USING btree (updated_at, id);

CREATE UNIQUE INDEX index_prometheus_alert_event_scoped_payload_key ON public.prometheus_alert_events USING btree (prometheus_alert_id, payload_key);

CREATE INDEX index_prometheus_alert_events_on_project_id_and_status ON public.prometheus_alert_events USING btree (project_id, status);

CREATE UNIQUE INDEX index_prometheus_alerts_metric_environment ON public.prometheus_alerts USING btree (project_id, prometheus_metric_id, environment_id);

CREATE INDEX index_prometheus_alerts_on_environment_id ON public.prometheus_alerts USING btree (environment_id);

CREATE INDEX index_prometheus_alerts_on_prometheus_metric_id ON public.prometheus_alerts USING btree (prometheus_metric_id);

CREATE INDEX index_prometheus_metrics_on_common ON public.prometheus_metrics USING btree (common);

CREATE INDEX index_prometheus_metrics_on_group ON public.prometheus_metrics USING btree ("group");

CREATE UNIQUE INDEX index_prometheus_metrics_on_identifier ON public.prometheus_metrics USING btree (identifier);

CREATE INDEX index_prometheus_metrics_on_project_id ON public.prometheus_metrics USING btree (project_id);

CREATE INDEX index_protected_branch_merge_access ON public.protected_branch_merge_access_levels USING btree (protected_branch_id);

CREATE INDEX index_protected_branch_merge_access_levels_on_group_id ON public.protected_branch_merge_access_levels USING btree (group_id);

CREATE INDEX index_protected_branch_merge_access_levels_on_user_id ON public.protected_branch_merge_access_levels USING btree (user_id);

CREATE INDEX index_protected_branch_push_access ON public.protected_branch_push_access_levels USING btree (protected_branch_id);

CREATE INDEX index_protected_branch_push_access_levels_on_group_id ON public.protected_branch_push_access_levels USING btree (group_id);

CREATE INDEX index_protected_branch_push_access_levels_on_user_id ON public.protected_branch_push_access_levels USING btree (user_id);

CREATE INDEX index_protected_branch_unprotect_access ON public.protected_branch_unprotect_access_levels USING btree (protected_branch_id);

CREATE INDEX index_protected_branch_unprotect_access_levels_on_group_id ON public.protected_branch_unprotect_access_levels USING btree (group_id);

CREATE INDEX index_protected_branch_unprotect_access_levels_on_user_id ON public.protected_branch_unprotect_access_levels USING btree (user_id);

CREATE INDEX index_protected_branches_on_project_id ON public.protected_branches USING btree (project_id);

CREATE INDEX index_protected_environment_deploy_access ON public.protected_environment_deploy_access_levels USING btree (protected_environment_id);

CREATE INDEX index_protected_environment_deploy_access_levels_on_group_id ON public.protected_environment_deploy_access_levels USING btree (group_id);

CREATE INDEX index_protected_environment_deploy_access_levels_on_user_id ON public.protected_environment_deploy_access_levels USING btree (user_id);

CREATE INDEX index_protected_environments_on_project_id ON public.protected_environments USING btree (project_id);

CREATE UNIQUE INDEX index_protected_environments_on_project_id_and_name ON public.protected_environments USING btree (project_id, name);

CREATE INDEX index_protected_tag_create_access ON public.protected_tag_create_access_levels USING btree (protected_tag_id);

CREATE INDEX index_protected_tag_create_access_levels_on_group_id ON public.protected_tag_create_access_levels USING btree (group_id);

CREATE INDEX index_protected_tag_create_access_levels_on_user_id ON public.protected_tag_create_access_levels USING btree (user_id);

CREATE INDEX index_protected_tags_on_project_id ON public.protected_tags USING btree (project_id);

CREATE UNIQUE INDEX index_protected_tags_on_project_id_and_name ON public.protected_tags USING btree (project_id, name);

CREATE UNIQUE INDEX index_push_event_payloads_on_event_id ON public.push_event_payloads USING btree (event_id);

CREATE INDEX index_push_rules_on_is_sample ON public.push_rules USING btree (is_sample) WHERE is_sample;

CREATE INDEX index_push_rules_on_project_id ON public.push_rules USING btree (project_id);

CREATE UNIQUE INDEX index_redirect_routes_on_path ON public.redirect_routes USING btree (path);

CREATE UNIQUE INDEX index_redirect_routes_on_path_unique_text_pattern_ops ON public.redirect_routes USING btree (lower((path)::text) varchar_pattern_ops);

CREATE INDEX index_redirect_routes_on_source_type_and_source_id ON public.redirect_routes USING btree (source_type, source_id);

CREATE UNIQUE INDEX index_release_links_on_release_id_and_name ON public.release_links USING btree (release_id, name);

CREATE UNIQUE INDEX index_release_links_on_release_id_and_url ON public.release_links USING btree (release_id, url);

CREATE INDEX index_releases_on_author_id ON public.releases USING btree (author_id);

CREATE INDEX index_releases_on_project_id_and_tag ON public.releases USING btree (project_id, tag);

CREATE INDEX index_remote_mirrors_on_last_successful_update_at ON public.remote_mirrors USING btree (last_successful_update_at);

CREATE INDEX index_remote_mirrors_on_project_id ON public.remote_mirrors USING btree (project_id);

CREATE UNIQUE INDEX index_repository_languages_on_project_and_languages_id ON public.repository_languages USING btree (project_id, programming_language_id);

CREATE INDEX index_requirements_management_test_reports_on_author_id ON public.requirements_management_test_reports USING btree (author_id);

CREATE INDEX index_requirements_management_test_reports_on_build_id ON public.requirements_management_test_reports USING btree (build_id);

CREATE INDEX index_requirements_management_test_reports_on_pipeline_id ON public.requirements_management_test_reports USING btree (pipeline_id);

CREATE INDEX index_requirements_management_test_reports_on_requirement_id ON public.requirements_management_test_reports USING btree (requirement_id);

CREATE INDEX index_requirements_on_author_id ON public.requirements USING btree (author_id);

CREATE INDEX index_requirements_on_created_at ON public.requirements USING btree (created_at);

CREATE INDEX index_requirements_on_project_id ON public.requirements USING btree (project_id);

CREATE UNIQUE INDEX index_requirements_on_project_id_and_iid ON public.requirements USING btree (project_id, iid) WHERE (project_id IS NOT NULL);

CREATE INDEX index_requirements_on_state ON public.requirements USING btree (state);

CREATE INDEX index_requirements_on_title_trigram ON public.requirements USING gin (title public.gin_trgm_ops);

CREATE INDEX index_requirements_on_updated_at ON public.requirements USING btree (updated_at);

CREATE INDEX index_resource_label_events_on_epic_id ON public.resource_label_events USING btree (epic_id);

CREATE INDEX index_resource_label_events_on_issue_id ON public.resource_label_events USING btree (issue_id);

CREATE INDEX index_resource_label_events_on_label_id_and_action ON public.resource_label_events USING btree (label_id, action);

CREATE INDEX index_resource_label_events_on_merge_request_id ON public.resource_label_events USING btree (merge_request_id);

CREATE INDEX index_resource_label_events_on_user_id ON public.resource_label_events USING btree (user_id);

CREATE INDEX index_resource_milestone_events_created_at ON public.resource_milestone_events USING btree (created_at);

CREATE INDEX index_resource_milestone_events_on_issue_id ON public.resource_milestone_events USING btree (issue_id);

CREATE INDEX index_resource_milestone_events_on_merge_request_id ON public.resource_milestone_events USING btree (merge_request_id);

CREATE INDEX index_resource_milestone_events_on_milestone_id ON public.resource_milestone_events USING btree (milestone_id);

CREATE INDEX index_resource_milestone_events_on_user_id ON public.resource_milestone_events USING btree (user_id);

CREATE INDEX index_resource_state_events_on_epic_id ON public.resource_state_events USING btree (epic_id);

CREATE INDEX index_resource_state_events_on_issue_id_and_created_at ON public.resource_state_events USING btree (issue_id, created_at);

CREATE INDEX index_resource_state_events_on_merge_request_id ON public.resource_state_events USING btree (merge_request_id);

CREATE INDEX index_resource_state_events_on_user_id ON public.resource_state_events USING btree (user_id);

CREATE INDEX index_resource_weight_events_on_issue_id_and_created_at ON public.resource_weight_events USING btree (issue_id, created_at);

CREATE INDEX index_resource_weight_events_on_issue_id_and_weight ON public.resource_weight_events USING btree (issue_id, weight);

CREATE INDEX index_resource_weight_events_on_user_id ON public.resource_weight_events USING btree (user_id);

CREATE INDEX index_reviews_on_author_id ON public.reviews USING btree (author_id);

CREATE INDEX index_reviews_on_merge_request_id ON public.reviews USING btree (merge_request_id);

CREATE INDEX index_reviews_on_project_id ON public.reviews USING btree (project_id);

CREATE UNIQUE INDEX index_routes_on_path ON public.routes USING btree (path);

CREATE INDEX index_routes_on_path_text_pattern_ops ON public.routes USING btree (path varchar_pattern_ops);

CREATE INDEX index_routes_on_path_trigram ON public.routes USING gin (path public.gin_trgm_ops);

CREATE UNIQUE INDEX index_routes_on_source_type_and_source_id ON public.routes USING btree (source_type, source_id);

CREATE INDEX index_saml_providers_on_group_id ON public.saml_providers USING btree (group_id);

CREATE INDEX index_scim_identities_on_group_id ON public.scim_identities USING btree (group_id);

CREATE UNIQUE INDEX index_scim_identities_on_lower_extern_uid_and_group_id ON public.scim_identities USING btree (lower((extern_uid)::text), group_id);

CREATE UNIQUE INDEX index_scim_identities_on_user_id_and_group_id ON public.scim_identities USING btree (user_id, group_id);

CREATE UNIQUE INDEX index_scim_oauth_access_tokens_on_group_id_and_token_encrypted ON public.scim_oauth_access_tokens USING btree (group_id, token_encrypted);

CREATE INDEX index_security_ci_builds_on_name_and_id ON public.ci_builds USING btree (name, id) WHERE (((name)::text = ANY (ARRAY[('container_scanning'::character varying)::text, ('dast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('license_management'::character varying)::text, ('sast'::character varying)::text, ('secret_detection'::character varying)::text, ('license_scanning'::character varying)::text])) AND ((type)::text = 'Ci::Build'::text));

CREATE INDEX index_self_managed_prometheus_alert_events_on_environment_id ON public.self_managed_prometheus_alert_events USING btree (environment_id);

CREATE INDEX index_sent_notifications_on_noteable_type_noteable_id ON public.sent_notifications USING btree (noteable_id) WHERE ((noteable_type)::text = 'Issue'::text);

CREATE UNIQUE INDEX index_sent_notifications_on_reply_key ON public.sent_notifications USING btree (reply_key);

CREATE UNIQUE INDEX index_sentry_issues_on_issue_id ON public.sentry_issues USING btree (issue_id);

CREATE INDEX index_sentry_issues_on_sentry_issue_identifier ON public.sentry_issues USING btree (sentry_issue_identifier);

CREATE INDEX index_serverless_domain_cluster_on_creator_id ON public.serverless_domain_cluster USING btree (creator_id);

CREATE INDEX index_serverless_domain_cluster_on_pages_domain_id ON public.serverless_domain_cluster USING btree (pages_domain_id);

CREATE INDEX index_service_desk_enabled_projects_on_id_creator_id_created_at ON public.projects USING btree (id, creator_id, created_at) WHERE (service_desk_enabled = true);

CREATE INDEX index_services_on_inherit_from_id ON public.services USING btree (inherit_from_id);

CREATE INDEX index_services_on_project_id_and_type ON public.services USING btree (project_id, type);

CREATE INDEX index_services_on_template ON public.services USING btree (template);

CREATE INDEX index_services_on_type ON public.services USING btree (type);

CREATE INDEX index_services_on_type_and_id_and_template_when_active ON public.services USING btree (type, id, template) WHERE (active = true);

CREATE UNIQUE INDEX index_services_on_type_and_instance_partial ON public.services USING btree (type, instance) WHERE (instance = true);

CREATE UNIQUE INDEX index_services_on_type_and_template_partial ON public.services USING btree (type, template) WHERE (template = true);

CREATE UNIQUE INDEX index_shards_on_name ON public.shards USING btree (name);

CREATE INDEX index_slack_integrations_on_service_id ON public.slack_integrations USING btree (service_id);

CREATE UNIQUE INDEX index_slack_integrations_on_team_id_and_alias ON public.slack_integrations USING btree (team_id, alias);

CREATE UNIQUE INDEX index_smartcard_identities_on_subject_and_issuer ON public.smartcard_identities USING btree (subject, issuer);

CREATE INDEX index_smartcard_identities_on_user_id ON public.smartcard_identities USING btree (user_id);

CREATE UNIQUE INDEX index_snippet_repositories_on_disk_path ON public.snippet_repositories USING btree (disk_path);

CREATE INDEX index_snippet_repositories_on_shard_id ON public.snippet_repositories USING btree (shard_id);

CREATE UNIQUE INDEX index_snippet_user_mentions_on_note_id ON public.snippet_user_mentions USING btree (note_id) WHERE (note_id IS NOT NULL);

CREATE INDEX index_snippets_on_author_id ON public.snippets USING btree (author_id);

CREATE INDEX index_snippets_on_content_trigram ON public.snippets USING gin (content public.gin_trgm_ops);

CREATE INDEX index_snippets_on_created_at ON public.snippets USING btree (created_at);

CREATE INDEX index_snippets_on_description_trigram ON public.snippets USING gin (description public.gin_trgm_ops);

CREATE INDEX index_snippets_on_file_name_trigram ON public.snippets USING gin (file_name public.gin_trgm_ops);

CREATE INDEX index_snippets_on_id_and_type ON public.snippets USING btree (id, type);

CREATE INDEX index_snippets_on_project_id_and_visibility_level ON public.snippets USING btree (project_id, visibility_level);

CREATE INDEX index_snippets_on_title_trigram ON public.snippets USING gin (title public.gin_trgm_ops);

CREATE INDEX index_snippets_on_updated_at ON public.snippets USING btree (updated_at);

CREATE INDEX index_snippets_on_visibility_level_and_secret ON public.snippets USING btree (visibility_level, secret);

CREATE INDEX index_software_license_policies_on_software_license_id ON public.software_license_policies USING btree (software_license_id);

CREATE UNIQUE INDEX index_software_license_policies_unique_per_project ON public.software_license_policies USING btree (project_id, software_license_id);

CREATE INDEX index_software_licenses_on_spdx_identifier ON public.software_licenses USING btree (spdx_identifier);

CREATE UNIQUE INDEX index_software_licenses_on_unique_name ON public.software_licenses USING btree (name);

CREATE INDEX index_sprints_on_description_trigram ON public.sprints USING gin (description public.gin_trgm_ops);

CREATE INDEX index_sprints_on_due_date ON public.sprints USING btree (due_date);

CREATE INDEX index_sprints_on_group_id ON public.sprints USING btree (group_id);

CREATE UNIQUE INDEX index_sprints_on_group_id_and_title ON public.sprints USING btree (group_id, title) WHERE (group_id IS NOT NULL);

CREATE UNIQUE INDEX index_sprints_on_project_id_and_iid ON public.sprints USING btree (project_id, iid);

CREATE UNIQUE INDEX index_sprints_on_project_id_and_title ON public.sprints USING btree (project_id, title) WHERE (project_id IS NOT NULL);

CREATE INDEX index_sprints_on_title ON public.sprints USING btree (title);

CREATE INDEX index_sprints_on_title_trigram ON public.sprints USING gin (title public.gin_trgm_ops);

CREATE UNIQUE INDEX index_status_page_published_incidents_on_issue_id ON public.status_page_published_incidents USING btree (issue_id);

CREATE INDEX index_status_page_settings_on_project_id ON public.status_page_settings USING btree (project_id);

CREATE INDEX index_subscriptions_on_project_id ON public.subscriptions USING btree (project_id);

CREATE UNIQUE INDEX index_subscriptions_on_subscribable_and_user_id_and_project_id ON public.subscriptions USING btree (subscribable_id, subscribable_type, user_id, project_id);

CREATE INDEX index_successful_deployments_on_cluster_id_and_environment_id ON public.deployments USING btree (cluster_id, environment_id) WHERE (status = 2);

CREATE UNIQUE INDEX index_suggestions_on_note_id_and_relative_order ON public.suggestions USING btree (note_id, relative_order);

CREATE UNIQUE INDEX index_system_note_metadata_on_description_version_id ON public.system_note_metadata USING btree (description_version_id) WHERE (description_version_id IS NOT NULL);

CREATE UNIQUE INDEX index_system_note_metadata_on_note_id ON public.system_note_metadata USING btree (note_id);

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type ON public.taggings USING btree (taggable_id, taggable_type);

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON public.taggings USING btree (taggable_id, taggable_type, context);

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);

CREATE INDEX index_tags_on_name_trigram ON public.tags USING gin (name public.gin_trgm_ops);

CREATE INDEX index_term_agreements_on_term_id ON public.term_agreements USING btree (term_id);

CREATE INDEX index_term_agreements_on_user_id ON public.term_agreements USING btree (user_id);

CREATE INDEX index_terraform_states_on_locked_by_user_id ON public.terraform_states USING btree (locked_by_user_id);

CREATE UNIQUE INDEX index_terraform_states_on_project_id_and_name ON public.terraform_states USING btree (project_id, name);

CREATE UNIQUE INDEX index_terraform_states_on_uuid ON public.terraform_states USING btree (uuid);

CREATE INDEX index_timelogs_on_issue_id ON public.timelogs USING btree (issue_id);

CREATE INDEX index_timelogs_on_merge_request_id ON public.timelogs USING btree (merge_request_id);

CREATE INDEX index_timelogs_on_spent_at ON public.timelogs USING btree (spent_at) WHERE (spent_at IS NOT NULL);

CREATE INDEX index_timelogs_on_user_id ON public.timelogs USING btree (user_id);

CREATE INDEX index_todos_on_author_id ON public.todos USING btree (author_id);

CREATE INDEX index_todos_on_author_id_and_created_at ON public.todos USING btree (author_id, created_at);

CREATE INDEX index_todos_on_commit_id ON public.todos USING btree (commit_id);

CREATE INDEX index_todos_on_group_id ON public.todos USING btree (group_id);

CREATE INDEX index_todos_on_note_id ON public.todos USING btree (note_id);

CREATE INDEX index_todos_on_project_id ON public.todos USING btree (project_id);

CREATE INDEX index_todos_on_target_type_and_target_id ON public.todos USING btree (target_type, target_id);

CREATE INDEX index_todos_on_user_id ON public.todos USING btree (user_id);

CREATE INDEX index_todos_on_user_id_and_id_done ON public.todos USING btree (user_id, id) WHERE ((state)::text = 'done'::text);

CREATE INDEX index_todos_on_user_id_and_id_pending ON public.todos USING btree (user_id, id) WHERE ((state)::text = 'pending'::text);

CREATE UNIQUE INDEX index_trending_projects_on_project_id ON public.trending_projects USING btree (project_id);

CREATE INDEX index_u2f_registrations_on_key_handle ON public.u2f_registrations USING btree (key_handle);

CREATE INDEX index_u2f_registrations_on_user_id ON public.u2f_registrations USING btree (user_id);

CREATE INDEX index_uploads_on_checksum ON public.uploads USING btree (checksum);

CREATE INDEX index_uploads_on_model_id_and_model_type ON public.uploads USING btree (model_id, model_type);

CREATE INDEX index_uploads_on_store ON public.uploads USING btree (store);

CREATE INDEX index_uploads_on_uploader_and_path ON public.uploads USING btree (uploader, path);

CREATE INDEX index_uploads_store_is_null ON public.uploads USING btree (id) WHERE (store IS NULL);

CREATE INDEX index_user_agent_details_on_subject_id_and_subject_type ON public.user_agent_details USING btree (subject_id, subject_type);

CREATE INDEX index_user_callouts_on_user_id ON public.user_callouts USING btree (user_id);

CREATE UNIQUE INDEX index_user_callouts_on_user_id_and_feature_name ON public.user_callouts USING btree (user_id, feature_name);

CREATE INDEX index_user_canonical_emails_on_canonical_email ON public.user_canonical_emails USING btree (canonical_email);

CREATE UNIQUE INDEX index_user_canonical_emails_on_user_id ON public.user_canonical_emails USING btree (user_id);

CREATE UNIQUE INDEX index_user_canonical_emails_on_user_id_and_canonical_email ON public.user_canonical_emails USING btree (user_id, canonical_email);

CREATE INDEX index_user_custom_attributes_on_key_and_value ON public.user_custom_attributes USING btree (key, value);

CREATE UNIQUE INDEX index_user_custom_attributes_on_user_id_and_key ON public.user_custom_attributes USING btree (user_id, key);

CREATE UNIQUE INDEX index_user_details_on_user_id ON public.user_details USING btree (user_id);

CREATE INDEX index_user_highest_roles_on_user_id_and_highest_access_level ON public.user_highest_roles USING btree (user_id, highest_access_level);

CREATE UNIQUE INDEX index_user_interacted_projects_on_project_id_and_user_id ON public.user_interacted_projects USING btree (project_id, user_id);

CREATE INDEX index_user_interacted_projects_on_user_id ON public.user_interacted_projects USING btree (user_id);

CREATE UNIQUE INDEX index_user_preferences_on_user_id ON public.user_preferences USING btree (user_id);

CREATE INDEX index_user_statuses_on_user_id ON public.user_statuses USING btree (user_id);

CREATE UNIQUE INDEX index_user_synced_attributes_metadata_on_user_id ON public.user_synced_attributes_metadata USING btree (user_id);

CREATE INDEX index_users_on_accepted_term_id ON public.users USING btree (accepted_term_id);

CREATE INDEX index_users_on_admin ON public.users USING btree (admin);

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);

CREATE INDEX index_users_on_created_at ON public.users USING btree (created_at);

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);

CREATE INDEX index_users_on_email_trigram ON public.users USING gin (email public.gin_trgm_ops);

CREATE INDEX index_users_on_feed_token ON public.users USING btree (feed_token);

CREATE INDEX index_users_on_group_view ON public.users USING btree (group_view);

CREATE INDEX index_users_on_incoming_email_token ON public.users USING btree (incoming_email_token);

CREATE INDEX index_users_on_managing_group_id ON public.users USING btree (managing_group_id);

CREATE INDEX index_users_on_name ON public.users USING btree (name);

CREATE INDEX index_users_on_name_trigram ON public.users USING gin (name public.gin_trgm_ops);

CREATE INDEX index_users_on_public_email ON public.users USING btree (public_email) WHERE ((public_email)::text <> ''::text);

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);

CREATE INDEX index_users_on_state ON public.users USING btree (state);

CREATE INDEX index_users_on_state_and_user_type ON public.users USING btree (state, user_type);

CREATE UNIQUE INDEX index_users_on_static_object_token ON public.users USING btree (static_object_token);

CREATE INDEX index_users_on_unconfirmed_email ON public.users USING btree (unconfirmed_email) WHERE (unconfirmed_email IS NOT NULL);

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);

CREATE INDEX index_users_on_user_type ON public.users USING btree (user_type);

CREATE INDEX index_users_on_username ON public.users USING btree (username);

CREATE INDEX index_users_on_username_trigram ON public.users USING gin (username public.gin_trgm_ops);

CREATE INDEX index_users_ops_dashboard_projects_on_project_id ON public.users_ops_dashboard_projects USING btree (project_id);

CREATE UNIQUE INDEX index_users_ops_dashboard_projects_on_user_id_and_project_id ON public.users_ops_dashboard_projects USING btree (user_id, project_id);

CREATE INDEX index_users_security_dashboard_projects_on_user_id ON public.users_security_dashboard_projects USING btree (user_id);

CREATE INDEX index_users_star_projects_on_project_id ON public.users_star_projects USING btree (project_id);

CREATE UNIQUE INDEX index_users_star_projects_on_user_id_and_project_id ON public.users_star_projects USING btree (user_id, project_id);

CREATE INDEX index_vulnerabilities_on_author_id ON public.vulnerabilities USING btree (author_id);

CREATE INDEX index_vulnerabilities_on_confirmed_by_id ON public.vulnerabilities USING btree (confirmed_by_id);

CREATE INDEX index_vulnerabilities_on_dismissed_by_id ON public.vulnerabilities USING btree (dismissed_by_id);

CREATE INDEX index_vulnerabilities_on_due_date_sourcing_milestone_id ON public.vulnerabilities USING btree (due_date_sourcing_milestone_id);

CREATE INDEX index_vulnerabilities_on_epic_id ON public.vulnerabilities USING btree (epic_id);

CREATE INDEX index_vulnerabilities_on_last_edited_by_id ON public.vulnerabilities USING btree (last_edited_by_id);

CREATE INDEX index_vulnerabilities_on_milestone_id ON public.vulnerabilities USING btree (milestone_id);

CREATE INDEX index_vulnerabilities_on_project_id ON public.vulnerabilities USING btree (project_id);

CREATE INDEX index_vulnerabilities_on_resolved_by_id ON public.vulnerabilities USING btree (resolved_by_id);

CREATE INDEX index_vulnerabilities_on_start_date_sourcing_milestone_id ON public.vulnerabilities USING btree (start_date_sourcing_milestone_id);

CREATE INDEX index_vulnerabilities_on_updated_by_id ON public.vulnerabilities USING btree (updated_by_id);

CREATE INDEX index_vulnerability_exports_on_author_id ON public.vulnerability_exports USING btree (author_id);

CREATE INDEX index_vulnerability_exports_on_group_id_not_null ON public.vulnerability_exports USING btree (group_id) WHERE (group_id IS NOT NULL);

CREATE INDEX index_vulnerability_exports_on_project_id_not_null ON public.vulnerability_exports USING btree (project_id) WHERE (project_id IS NOT NULL);

CREATE INDEX index_vulnerability_feedback_on_author_id ON public.vulnerability_feedback USING btree (author_id);

CREATE INDEX index_vulnerability_feedback_on_comment_author_id ON public.vulnerability_feedback USING btree (comment_author_id);

CREATE INDEX index_vulnerability_feedback_on_issue_id ON public.vulnerability_feedback USING btree (issue_id);

CREATE INDEX index_vulnerability_feedback_on_merge_request_id ON public.vulnerability_feedback USING btree (merge_request_id);

CREATE INDEX index_vulnerability_feedback_on_pipeline_id ON public.vulnerability_feedback USING btree (pipeline_id);

CREATE UNIQUE INDEX index_vulnerability_identifiers_on_project_id_and_fingerprint ON public.vulnerability_identifiers USING btree (project_id, fingerprint);

CREATE INDEX index_vulnerability_issue_links_on_issue_id ON public.vulnerability_issue_links USING btree (issue_id);

CREATE INDEX index_vulnerability_occurrence_identifiers_on_identifier_id ON public.vulnerability_occurrence_identifiers USING btree (identifier_id);

CREATE UNIQUE INDEX index_vulnerability_occurrence_identifiers_on_unique_keys ON public.vulnerability_occurrence_identifiers USING btree (occurrence_id, identifier_id);

CREATE INDEX index_vulnerability_occurrence_pipelines_on_pipeline_id ON public.vulnerability_occurrence_pipelines USING btree (pipeline_id);

CREATE INDEX index_vulnerability_occurrences_on_primary_identifier_id ON public.vulnerability_occurrences USING btree (primary_identifier_id);

CREATE INDEX index_vulnerability_occurrences_on_scanner_id ON public.vulnerability_occurrences USING btree (scanner_id);

CREATE UNIQUE INDEX index_vulnerability_occurrences_on_unique_keys ON public.vulnerability_occurrences USING btree (project_id, primary_identifier_id, location_fingerprint, scanner_id);

CREATE UNIQUE INDEX index_vulnerability_occurrences_on_uuid ON public.vulnerability_occurrences USING btree (uuid);

CREATE INDEX index_vulnerability_occurrences_on_vulnerability_id ON public.vulnerability_occurrences USING btree (vulnerability_id);

CREATE UNIQUE INDEX index_vulnerability_scanners_on_project_id_and_external_id ON public.vulnerability_scanners USING btree (project_id, external_id);

CREATE UNIQUE INDEX index_vulnerability_user_mentions_on_note_id ON public.vulnerability_user_mentions USING btree (note_id) WHERE (note_id IS NOT NULL);

CREATE UNIQUE INDEX index_vulns_user_mentions_on_vulnerability_id ON public.vulnerability_user_mentions USING btree (vulnerability_id) WHERE (note_id IS NULL);

CREATE UNIQUE INDEX index_vulns_user_mentions_on_vulnerability_id_and_note_id ON public.vulnerability_user_mentions USING btree (vulnerability_id, note_id);

CREATE INDEX index_web_hook_logs_on_created_at_and_web_hook_id ON public.web_hook_logs USING btree (created_at, web_hook_id);

CREATE INDEX index_web_hook_logs_on_web_hook_id ON public.web_hook_logs USING btree (web_hook_id);

CREATE INDEX index_web_hooks_on_group_id ON public.web_hooks USING btree (group_id) WHERE ((type)::text = 'GroupHook'::text);

CREATE INDEX index_web_hooks_on_project_id ON public.web_hooks USING btree (project_id);

CREATE INDEX index_web_hooks_on_type ON public.web_hooks USING btree (type);

CREATE INDEX index_wiki_page_meta_on_project_id ON public.wiki_page_meta USING btree (project_id);

CREATE UNIQUE INDEX index_wiki_page_slugs_on_slug_and_wiki_page_meta_id ON public.wiki_page_slugs USING btree (slug, wiki_page_meta_id);

CREATE INDEX index_wiki_page_slugs_on_wiki_page_meta_id ON public.wiki_page_slugs USING btree (wiki_page_meta_id);

CREATE INDEX index_x509_certificates_on_subject_key_identifier ON public.x509_certificates USING btree (subject_key_identifier);

CREATE INDEX index_x509_certificates_on_x509_issuer_id ON public.x509_certificates USING btree (x509_issuer_id);

CREATE INDEX index_x509_commit_signatures_on_commit_sha ON public.x509_commit_signatures USING btree (commit_sha);

CREATE INDEX index_x509_commit_signatures_on_project_id ON public.x509_commit_signatures USING btree (project_id);

CREATE INDEX index_x509_commit_signatures_on_x509_certificate_id ON public.x509_commit_signatures USING btree (x509_certificate_id);

CREATE INDEX index_x509_issuers_on_subject_key_identifier ON public.x509_issuers USING btree (subject_key_identifier);

CREATE INDEX index_zoom_meetings_on_issue_id ON public.zoom_meetings USING btree (issue_id);

CREATE UNIQUE INDEX index_zoom_meetings_on_issue_id_and_issue_status ON public.zoom_meetings USING btree (issue_id, issue_status) WHERE (issue_status = 1);

CREATE INDEX index_zoom_meetings_on_issue_status ON public.zoom_meetings USING btree (issue_status);

CREATE INDEX index_zoom_meetings_on_project_id ON public.zoom_meetings USING btree (project_id);

CREATE INDEX issue_id_issues_prometheus_alert_events_index ON public.issues_prometheus_alert_events USING btree (prometheus_alert_event_id);

CREATE INDEX issue_id_issues_self_managed_rometheus_alert_events_index ON public.issues_self_managed_prometheus_alert_events USING btree (self_managed_prometheus_alert_event_id);

CREATE UNIQUE INDEX issue_id_prometheus_alert_event_id_index ON public.issues_prometheus_alert_events USING btree (issue_id, prometheus_alert_event_id);

CREATE UNIQUE INDEX issue_id_self_managed_prometheus_alert_event_id_index ON public.issues_self_managed_prometheus_alert_events USING btree (issue_id, self_managed_prometheus_alert_event_id);

CREATE UNIQUE INDEX issue_user_mentions_on_issue_id_and_note_id_index ON public.issue_user_mentions USING btree (issue_id, note_id);

CREATE UNIQUE INDEX issue_user_mentions_on_issue_id_index ON public.issue_user_mentions USING btree (issue_id) WHERE (note_id IS NULL);

CREATE UNIQUE INDEX kubernetes_namespaces_cluster_and_namespace ON public.clusters_kubernetes_namespaces USING btree (cluster_id, namespace);

CREATE INDEX merge_request_mentions_temp_index ON public.merge_requests USING btree (id) WHERE ((description ~~ '%@%'::text) OR ((title)::text ~~ '%@%'::text));

CREATE UNIQUE INDEX merge_request_user_mentions_on_mr_id_and_note_id_index ON public.merge_request_user_mentions USING btree (merge_request_id, note_id);

CREATE UNIQUE INDEX merge_request_user_mentions_on_mr_id_index ON public.merge_request_user_mentions USING btree (merge_request_id) WHERE (note_id IS NULL);

CREATE INDEX note_mentions_temp_index ON public.notes USING btree (id, noteable_type) WHERE (note ~~ '%@%'::text);

CREATE UNIQUE INDEX one_canonical_wiki_page_slug_per_metadata ON public.wiki_page_slugs USING btree (wiki_page_meta_id) WHERE (canonical = true);

CREATE INDEX package_name_index ON public.packages_packages USING btree (name);

CREATE INDEX packages_packages_verification_checksum_partial ON public.packages_package_files USING btree (verification_checksum) WHERE (verification_checksum IS NOT NULL);

CREATE INDEX packages_packages_verification_failure_partial ON public.packages_package_files USING btree (verification_failure) WHERE (verification_failure IS NOT NULL);

CREATE INDEX partial_index_ci_builds_on_scheduled_at_with_scheduled_jobs ON public.ci_builds USING btree (scheduled_at) WHERE ((scheduled_at IS NOT NULL) AND ((type)::text = 'Ci::Build'::text) AND ((status)::text = 'scheduled'::text));

CREATE INDEX partial_index_deployments_for_legacy_successful_deployments ON public.deployments USING btree (id) WHERE ((finished_at IS NULL) AND (status = 2));

CREATE INDEX partial_index_deployments_for_project_id_and_tag ON public.deployments USING btree (project_id) WHERE (tag IS TRUE);

CREATE UNIQUE INDEX snippet_user_mentions_on_snippet_id_and_note_id_index ON public.snippet_user_mentions USING btree (snippet_id, note_id);

CREATE UNIQUE INDEX snippet_user_mentions_on_snippet_id_index ON public.snippet_user_mentions USING btree (snippet_id) WHERE (note_id IS NULL);

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);

CREATE UNIQUE INDEX term_agreements_unique_index ON public.term_agreements USING btree (user_id, term_id);

CREATE INDEX tmp_build_stage_position_index ON public.ci_builds USING btree (stage_id, stage_idx) WHERE (stage_idx IS NOT NULL);

CREATE INDEX tmp_idx_on_user_id_where_bio_is_filled ON public.users USING btree (id) WHERE ((COALESCE(bio, ''::character varying))::text IS DISTINCT FROM ''::text);

CREATE INDEX tmp_index_ci_builds_lock_version ON public.ci_builds USING btree (id) WHERE (lock_version IS NULL);

CREATE INDEX tmp_index_ci_pipelines_lock_version ON public.ci_pipelines USING btree (id) WHERE (lock_version IS NULL);

CREATE INDEX tmp_index_ci_stages_lock_version ON public.ci_stages USING btree (id) WHERE (lock_version IS NULL);

CREATE UNIQUE INDEX users_security_dashboard_projects_unique_index ON public.users_security_dashboard_projects USING btree (project_id, user_id);

CREATE UNIQUE INDEX vulnerability_feedback_unique_idx ON public.vulnerability_feedback USING btree (project_id, category, feedback_type, project_fingerprint);

CREATE UNIQUE INDEX vulnerability_occurrence_pipelines_on_unique_keys ON public.vulnerability_occurrence_pipelines USING btree (occurrence_id, pipeline_id);

ALTER TABLE ONLY public.chat_names
    ADD CONSTRAINT fk_00797a2bf9 FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_013c9f36ca FOREIGN KEY (due_date_sourcing_epic_id) REFERENCES public.epics(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.clusters_applications_runners
    ADD CONSTRAINT fk_02de2ded36 FOREIGN KEY (runner_id) REFERENCES public.ci_runners(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.design_management_designs_versions
    ADD CONSTRAINT fk_03c671965c FOREIGN KEY (design_id) REFERENCES public.design_management_designs(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_05f1e72feb FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_06067f5644 FOREIGN KEY (latest_merge_request_diff_id) REFERENCES public.merge_request_diffs(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.user_interacted_projects
    ADD CONSTRAINT fk_0894651f08 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.web_hooks
    ADD CONSTRAINT fk_0c8ca6d9d1 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT fk_0c95e91db7 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT fk_0d3f677137 FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_deletion_schedules
    ADD CONSTRAINT fk_11e3ebfcdd FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_1302949740 FOREIGN KEY (last_edited_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_131d289c65 FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.internal_ids
    ADD CONSTRAINT fk_162941d509 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_176d3fbb5d FOREIGN KEY (job_artifact_deleted_event_id) REFERENCES public.geo_job_artifact_deleted_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_features
    ADD CONSTRAINT fk_18513d9b92 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT fk_190998ef09 FOREIGN KEY (external_pull_request_id) REFERENCES public.external_pull_requests(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_1d37cddf91 FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT fk_1e53c97c0a FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT fk_1e9a074a35 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_1fbed67632 FOREIGN KEY (start_date_sourcing_milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_container_repository_updated_events
    ADD CONSTRAINT fk_212c89c706 FOREIGN KEY (container_repository_id) REFERENCES public.container_repositories(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users_star_projects
    ADD CONSTRAINT fk_22cd27ddfc FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.alert_management_alerts
    ADD CONSTRAINT fk_2358b75436 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_stages
    ADD CONSTRAINT fk_2360681d1d FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.import_failures
    ADD CONSTRAINT fk_24b824da43 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_ci_cd_settings
    ADD CONSTRAINT fk_24c15d2f2e FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_25b99c1be3 FOREIGN KEY (parent_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_25d8780d11 FOREIGN KEY (marked_for_deletion_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT fk_262d4c2d19 FOREIGN KEY (auto_canceled_by_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_build_trace_sections
    ADD CONSTRAINT fk_264e112c66 FOREIGN KEY (section_name_id) REFERENCES public.ci_build_trace_section_names(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_27548c6db3 FOREIGN KEY (hashed_storage_migrated_event_id) REFERENCES public.geo_hashed_storage_migrated_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployments
    ADD CONSTRAINT fk_289bba3222 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_2e82291620 FOREIGN KEY (review_id) REFERENCES public.reviews(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_2e88fb7ce9 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT fk_310d714958 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT fk_319256d87a FOREIGN KEY (file_template_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_3308fe130c FOREIGN KEY (source_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_group_variables
    ADD CONSTRAINT fk_33ae4d58d8 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT fk_3448c97865 FOREIGN KEY (push_rule_id) REFERENCES public.push_rules(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_3654b61b03 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.push_event_payloads
    ADD CONSTRAINT fk_36c74129da FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT fk_3a9eaa254d FOREIGN KEY (stage_id) REFERENCES public.ci_stages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_3b8c72ea56 FOREIGN KEY (sprint_id) REFERENCES public.sprints(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_3c1fd1cccc FOREIGN KEY (due_date_sourcing_milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT fk_3d34ab2e06 FOREIGN KEY (pipeline_schedule_id) REFERENCES public.ci_pipeline_schedules(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_pipeline_schedule_variables
    ADD CONSTRAINT fk_41c35fda51 FOREIGN KEY (pipeline_schedule_id) REFERENCES public.ci_pipeline_schedules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_42c3b54bed FOREIGN KEY (cache_invalidation_event_id) REFERENCES public.geo_cache_invalidation_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.remote_mirrors
    ADD CONSTRAINT fk_43a9aa4ca8 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_runner_projects
    ADD CONSTRAINT fk_4478a6f1e4 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT fk_45054f9c45 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_47fe2a0596 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_4a99ebfd60 FOREIGN KEY (repositories_changed_event_id) REFERENCES public.geo_repositories_changed_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_trace_sections
    ADD CONSTRAINT fk_4ebe41f502 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.path_locks
    ADD CONSTRAINT fk_5265c98f24 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_prometheus
    ADD CONSTRAINT fk_557e773639 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT fk_563ff1912e FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.deploy_keys_projects
    ADD CONSTRAINT fk_58a901ca7e FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issue_assignees
    ADD CONSTRAINT fk_5e0c8d9154 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_6149611a04 FOREIGN KEY (assignee_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_61fbf6ca48 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_641731faff FOREIGN KEY (updated_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT fk_6661f4f0e8 FOREIGN KEY (resource_group_id) REFERENCES public.ci_resource_groups(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT fk_693b8795e4 FOREIGN KEY (push_rule_id) REFERENCES public.push_rules(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_6a5165a692 FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_6ada82d42a FOREIGN KEY (container_repository_updated_event_id) REFERENCES public.geo_container_repository_updated_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_6e5c14658a FOREIGN KEY (pool_repository_id) REFERENCES public.pool_repositories(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.protected_branch_push_access_levels
    ADD CONSTRAINT fk_7111b68cdb FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_71cce407f9 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_interacted_projects
    ADD CONSTRAINT fk_722ceba4f7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_725465b774 FOREIGN KEY (dismissed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.index_statuses
    ADD CONSTRAINT fk_74b2492545 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_76bc5f5455 FOREIGN KEY (resolved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.oauth_openid_requests
    ADD CONSTRAINT fk_77114b3b09 FOREIGN KEY (access_grant_id) REFERENCES public.oauth_access_grants(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_resource_groups
    ADD CONSTRAINT fk_774722d144 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_789cd90b35 FOREIGN KEY (accepted_term_id) REFERENCES public.application_setting_terms(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_78a6492f68 FOREIGN KEY (repository_updated_event_id) REFERENCES public.geo_repository_updated_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT fk_7a5553d60f FOREIGN KEY (label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_branches
    ADD CONSTRAINT fk_7a9c6d93e7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_7ac31eacb9 FOREIGN KEY (updated_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_7c5bb22a22 FOREIGN KEY (due_date_sourcing_milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT fk_7de4989a69 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_7e85395a64 FOREIGN KEY (sprint_id) REFERENCES public.sprints(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_metrics
    ADD CONSTRAINT fk_7f28d925f3 FOREIGN KEY (merged_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.sprints
    ADD CONSTRAINT fk_80aa8a1f95 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.import_export_uploads
    ADD CONSTRAINT fk_83319d9721 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.push_rules
    ADD CONSTRAINT fk_83b29894de FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_diffs
    ADD CONSTRAINT fk_8483f3258f FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT fk_86635dbd80 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_868a8e7ad6 FOREIGN KEY (inherit_from_id) REFERENCES public.services(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_86c84214ec FOREIGN KEY (repository_renamed_event_id) REFERENCES public.geo_repository_renamed_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_package_files
    ADD CONSTRAINT fk_86f0f182f8 FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT fk_87f4cefcda FOREIGN KEY (upstream_pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_88b4d546ef FOREIGN KEY (start_date_sourcing_milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_899c8f3231 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_branch_merge_access_levels
    ADD CONSTRAINT fk_8a3072ccb3 FOREIGN KEY (protected_branch_id) REFERENCES public.protected_branches(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_8e4456f90f FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.protected_tags
    ADD CONSTRAINT fk_8e4af87648 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipeline_schedules
    ADD CONSTRAINT fk_8ead60fcc4 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT fk_91d1f47b13 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT fk_94f7c8a81e FOREIGN KEY (comment_author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.milestones
    ADD CONSTRAINT fk_95650a40d4 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_959d40ad0a FOREIGN KEY (confirmed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT fk_964370041d FOREIGN KEY (usage_stats_set_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_96b1dd429c FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerability_occurrences
    ADD CONSTRAINT fk_97ffe77653 FOREIGN KEY (vulnerability_id) REFERENCES public.vulnerabilities(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.protected_branch_merge_access_levels
    ADD CONSTRAINT fk_98f3d044fe FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_99e097b079 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_9b9afb1916 FOREIGN KEY (repository_created_event_id) REFERENCES public.geo_repository_created_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.milestones
    ADD CONSTRAINT fk_9bd0a0c791 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_9c4516d665 FOREIGN KEY (duplicated_to_id) REFERENCES public.issues(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_9d480c64b2 FOREIGN KEY (start_date_sourcing_epic_id) REFERENCES public.epics(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.alert_management_alerts
    ADD CONSTRAINT fk_9e49e5c2b7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipeline_schedules
    ADD CONSTRAINT fk_9ea99f58d2 FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.protected_branch_push_access_levels
    ADD CONSTRAINT fk_9ffc86a3d9 FOREIGN KEY (protected_branch_id) REFERENCES public.protected_branches(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployment_merge_requests
    ADD CONSTRAINT fk_a064ff4453 FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_a194299be1 FOREIGN KEY (moved_to_id) REFERENCES public.issues(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT fk_a2141b1522 FOREIGN KEY (auto_canceled_by_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT fk_a23be95014 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_a4b8fefe3e FOREIGN KEY (managing_group_id) REFERENCES public.namespaces(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_a6963e8447 FOREIGN KEY (target_project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_aa5798e761 FOREIGN KEY (closed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT fk_aade90f0fc FOREIGN KEY (saml_provider_id) REFERENCES public.saml_providers(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT fk_acd9737679 FOREIGN KEY (source_project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_ad525e1f87 FOREIGN KEY (merge_user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_variables
    ADD CONSTRAINT fk_ada5eb64b3 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_metrics
    ADD CONSTRAINT fk_ae440388cc FOREIGN KEY (latest_closed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.fork_network_members
    ADD CONSTRAINT fk_b01280dae4 FOREIGN KEY (forked_from_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_b1de915a15 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.protected_tag_create_access_levels
    ADD CONSTRAINT fk_b4eb82fe3c FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issue_assignees
    ADD CONSTRAINT fk_b7d881734a FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_trigger_requests
    ADD CONSTRAINT fk_b8ec8b7245 FOREIGN KEY (trigger_id) REFERENCES public.ci_triggers(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployments
    ADD CONSTRAINT fk_b9a3851b82 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gitlab_subscriptions
    ADD CONSTRAINT fk_bd0c4019c3 FOREIGN KEY (hosted_plan_id) REFERENCES public.plans(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.metrics_users_starred_dashboards
    ADD CONSTRAINT fk_bd6ae32fac FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.snippets
    ADD CONSTRAINT fk_be41fd4bb7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT fk_be5624bf37 FOREIGN KEY (source_job_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_maven_metadata
    ADD CONSTRAINT fk_be88aed360 FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT fk_befce0568a FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.design_management_versions
    ADD CONSTRAINT fk_c1440b4896 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_c1f241c70d FOREIGN KEY (upload_deleted_event_id) REFERENCES public.geo_upload_deleted_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_exports
    ADD CONSTRAINT fk_c3d3cb5d0f FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_c4b1c1f66e FOREIGN KEY (repository_deleted_event_id) REFERENCES public.geo_repository_deleted_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_c63cbf6c25 FOREIGN KEY (closed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.issue_links
    ADD CONSTRAINT fk_c900194ff2 FOREIGN KEY (source_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT fk_ccf0373936 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_cff7185ad2 FOREIGN KEY (reset_checksum_event_id) REFERENCES public.geo_reset_checksum_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_mirror_data
    ADD CONSTRAINT fk_d1aad367d7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT fk_d1c8c1da6a FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT fk_d3130c9a7f FOREIGN KEY (commit_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT fk_d4e29af7d7 FOREIGN KEY (source_pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_d5af95fcd9 FOREIGN KEY (lfs_object_deleted_event_id) REFERENCES public.geo_lfs_object_deleted_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT fk_d6cf4279f7 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.metrics_users_starred_dashboards
    ADD CONSTRAINT fk_d76a2b9a8c FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT fk_d80e161c54 FOREIGN KEY (ci_ref_id) REFERENCES public.ci_refs(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.system_note_metadata
    ADD CONSTRAINT fk_d83a918cb1 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT fk_d94154aa95 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.label_links
    ADD CONSTRAINT fk_d97dd08678 FOREIGN KEY (label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_group_links
    ADD CONSTRAINT fk_daa8cee94c FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_dccd3f98fc FOREIGN KEY (assignee_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_df75a7c8b8 FOREIGN KEY (promoted_to_epic_id) REFERENCES public.epics(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_resources
    ADD CONSTRAINT fk_e169a8e3d5 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT fk_e1bad85861 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gitlab_subscriptions
    ADD CONSTRAINT fk_e2595d00a1 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_triggers
    ADD CONSTRAINT fk_e3e63f966e FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_e719a85f8a FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.issue_links
    ADD CONSTRAINT fk_e71bb44f1f FOREIGN KEY (target_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT fk_e7a0b20a6b FOREIGN KEY (custom_project_templates_group_id) REFERENCES public.namespaces(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.fork_networks
    ADD CONSTRAINT fk_e7b436b2b5 FOREIGN KEY (root_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.sprints
    ADD CONSTRAINT fk_e8206c9686 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT fk_e8a145f3a7 FOREIGN KEY (instance_administrators_group_id) REFERENCES public.namespaces(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_triggers
    ADD CONSTRAINT fk_e8e10d1964 FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pages_domains
    ADD CONSTRAINT fk_ea2f6dfc6f FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT fk_ec757bd087 FOREIGN KEY (file_template_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_edfd187b6f FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT fk_efb96ab1e2 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters
    ADD CONSTRAINT fk_f05c5e5a42 FOREIGN KEY (management_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.epics
    ADD CONSTRAINT fk_f081aa4489 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT fk_f15266b5f9 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipeline_variables
    ADD CONSTRAINT fk_f29c5f4380 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.design_management_designs_versions
    ADD CONSTRAINT fk_f4d25ba00c FOREIGN KEY (version_id) REFERENCES public.design_management_versions(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_tag_create_access_levels
    ADD CONSTRAINT fk_f7dfda8c51 FOREIGN KEY (protected_tag_id) REFERENCES public.protected_tags(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_stages
    ADD CONSTRAINT fk_fb57e6cc56 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.system_note_metadata
    ADD CONSTRAINT fk_fbd87415c9 FOREIGN KEY (description_version_id) REFERENCES public.description_versions(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT fk_fd82eae0b9 FOREIGN KEY (head_pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.project_import_data
    ADD CONSTRAINT fk_ffb9ee3a10 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_ffed080f01 FOREIGN KEY (updated_by_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_event_log
    ADD CONSTRAINT fk_geo_event_log_on_geo_event_id FOREIGN KEY (geo_event_id) REFERENCES public.geo_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.path_locks
    ADD CONSTRAINT fk_path_locks_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT fk_personal_access_tokens_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_settings
    ADD CONSTRAINT fk_project_settings_push_rule_id FOREIGN KEY (push_rule_id) REFERENCES public.push_rules(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_namespace_id FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.protected_branch_merge_access_levels
    ADD CONSTRAINT fk_protected_branch_merge_access_levels_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_branch_push_access_levels
    ADD CONSTRAINT fk_protected_branch_push_access_levels_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_tag_create_access_levels
    ADD CONSTRAINT fk_protected_tag_create_access_levels_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rules
    ADD CONSTRAINT fk_rails_004ce82224 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.namespace_statistics
    ADD CONSTRAINT fk_rails_0062050394 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_elastic_stacks
    ADD CONSTRAINT fk_rails_026f219f46 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_0434b48643 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ip_restrictions
    ADD CONSTRAINT fk_rails_04a93778d5 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_report_results
    ADD CONSTRAINT fk_rails_056d298d48 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_daily_build_group_report_results
    ADD CONSTRAINT fk_rails_0667f7608c FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_subscriptions_projects
    ADD CONSTRAINT fk_rails_0818751483 FOREIGN KEY (downstream_project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.trending_projects
    ADD CONSTRAINT fk_rails_09feecd872 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_deploy_tokens
    ADD CONSTRAINT fk_rails_0aca134388 FOREIGN KEY (deploy_token_id) REFERENCES public.deploy_tokens(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_conan_file_metadata
    ADD CONSTRAINT fk_rails_0afabd9328 FOREIGN KEY (package_file_id) REFERENCES public.packages_package_files(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_user_lists
    ADD CONSTRAINT fk_rails_0c716e079b FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_node_statuses
    ADD CONSTRAINT fk_rails_0ecc699c2a FOREIGN KEY (geo_node_id) REFERENCES public.geo_nodes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_repository_states
    ADD CONSTRAINT fk_rails_0f2298ca8a FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_synced_attributes_metadata
    ADD CONSTRAINT fk_rails_0f4aa0981f FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_authorizations
    ADD CONSTRAINT fk_rails_0f84bb11f3 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_context_commits
    ADD CONSTRAINT fk_rails_0fe0039f60 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_trace_chunks
    ADD CONSTRAINT fk_rails_1013b761f2 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_exports
    ADD CONSTRAINT fk_rails_1019162882 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.prometheus_alert_events
    ADD CONSTRAINT fk_rails_106f901176 FOREIGN KEY (prometheus_alert_id) REFERENCES public.prometheus_alerts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_sources_projects
    ADD CONSTRAINT fk_rails_10a1eb379a FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.zoom_meetings
    ADD CONSTRAINT fk_rails_1190f0e0fa FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gpg_signatures
    ADD CONSTRAINT fk_rails_11ae8cb9a7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_authorizations
    ADD CONSTRAINT fk_rails_11e7aa3ed9 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.description_versions
    ADD CONSTRAINT fk_rails_12b144011c FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_statistics
    ADD CONSTRAINT fk_rails_12c471002f FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_details
    ADD CONSTRAINT fk_rails_12e0b3043d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.diff_note_positions
    ADD CONSTRAINT fk_rails_13c7212859 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users_security_dashboard_projects
    ADD CONSTRAINT fk_rails_150cd5682c FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_report_results
    ADD CONSTRAINT fk_rails_16cb1ff064 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_deploy_tokens
    ADD CONSTRAINT fk_rails_170e03cbaf FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_cycle_analytics_project_stages
    ADD CONSTRAINT fk_rails_1722574860 FOREIGN KEY (start_event_label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_build_infos
    ADD CONSTRAINT fk_rails_17a9a0dffc FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.clusters_applications_jupyter
    ADD CONSTRAINT fk_rails_17df21c98c FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_providers_aws
    ADD CONSTRAINT fk_rails_18983d9ea4 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.grafana_integrations
    ADD CONSTRAINT fk_rails_18d0e2b564 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_wiki_repositories
    ADD CONSTRAINT fk_rails_19755e374b FOREIGN KEY (shard_id) REFERENCES public.shards(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.open_project_tracker_data
    ADD CONSTRAINT fk_rails_1987546e48 FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gpg_signatures
    ADD CONSTRAINT fk_rails_19d4f1c6f9 FOREIGN KEY (gpg_key_subkey_id) REFERENCES public.gpg_key_subkeys(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerability_user_mentions
    ADD CONSTRAINT fk_rails_1a41c485cd FOREIGN KEY (vulnerability_id) REFERENCES public.vulnerabilities(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_assignees
    ADD CONSTRAINT fk_rails_1c0ff59e82 FOREIGN KEY (assignee_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epic_user_mentions
    ADD CONSTRAINT fk_rails_1c65976a49 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approver_groups
    ADD CONSTRAINT fk_rails_1cdcbd7723 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_tags
    ADD CONSTRAINT fk_rails_1dfc868911 FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_repository_created_events
    ADD CONSTRAINT fk_rails_1f49e46a61 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rules_groups
    ADD CONSTRAINT fk_rails_2020a7124a FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT fk_rails_20976e6fd9 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.user_statuses
    ADD CONSTRAINT fk_rails_2178592333 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users_ops_dashboard_projects
    ADD CONSTRAINT fk_rails_220a0562db FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_runners
    ADD CONSTRAINT fk_rails_22388594e9 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.service_desk_settings
    ADD CONSTRAINT fk_rails_223a296a85 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_custom_attributes
    ADD CONSTRAINT fk_rails_246e0db83a FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requirements_management_test_reports
    ADD CONSTRAINT fk_rails_24cecc1e68 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.group_wiki_repositories
    ADD CONSTRAINT fk_rails_26f867598c FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.lfs_file_locks
    ADD CONSTRAINT fk_rails_27a1d98fa8 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_alerting_settings
    ADD CONSTRAINT fk_rails_27a84b407d FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_state_events
    ADD CONSTRAINT fk_rails_29af06892a FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_29e6f859c4 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.draft_notes
    ADD CONSTRAINT fk_rails_2a8dac9901 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_group_links
    ADD CONSTRAINT fk_rails_2b2353ca49 FOREIGN KEY (shared_with_group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_repository_updated_events
    ADD CONSTRAINT fk_rails_2b70854c08 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_branch_unprotect_access_levels
    ADD CONSTRAINT fk_rails_2d2aba21ef FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_freeze_periods
    ADD CONSTRAINT fk_rails_2e02bbd1a6 FOREIGN KEY (project_id) REFERENCES public.projects(id);

ALTER TABLE ONLY public.saml_providers
    ADD CONSTRAINT fk_rails_306d459be7 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_state_events
    ADD CONSTRAINT fk_rails_3112bba7dc FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_diff_commits
    ADD CONSTRAINT fk_rails_316aaceda3 FOREIGN KEY (merge_request_diff_id) REFERENCES public.merge_request_diffs(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_import_states
    ADD CONSTRAINT fk_rails_31c3e0503a FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.zoom_meetings
    ADD CONSTRAINT fk_rails_3263f29616 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.container_repositories
    ADD CONSTRAINT fk_rails_32f7bf5aad FOREIGN KEY (project_id) REFERENCES public.projects(id);

ALTER TABLE ONLY public.clusters_applications_jupyter
    ADD CONSTRAINT fk_rails_331f0aff78 FOREIGN KEY (oauth_application_id) REFERENCES public.oauth_applications(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_request_metrics
    ADD CONSTRAINT fk_rails_33ae169d48 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.suggestions
    ADD CONSTRAINT fk_rails_33b03a535c FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT fk_rails_33fed8aa4e FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.metrics_dashboard_annotations
    ADD CONSTRAINT fk_rails_345ab51043 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.wiki_page_slugs
    ADD CONSTRAINT fk_rails_358b46be14 FOREIGN KEY (wiki_page_meta_id) REFERENCES public.wiki_page_meta(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_labels
    ADD CONSTRAINT fk_rails_362b0600a3 FOREIGN KEY (label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_blocks
    ADD CONSTRAINT fk_rails_364d4bea8b FOREIGN KEY (blocked_merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_cycle_analytics_project_stages
    ADD CONSTRAINT fk_rails_3829e49b66 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issue_user_mentions
    ADD CONSTRAINT fk_rails_3861d9fefa FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.self_managed_prometheus_alert_events
    ADD CONSTRAINT fk_rails_3936dadc62 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules_groups
    ADD CONSTRAINT fk_rails_396841e79e FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.self_managed_prometheus_alert_events
    ADD CONSTRAINT fk_rails_39d83d1b65 FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.chat_teams
    ADD CONSTRAINT fk_rails_3b543909cb FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_needs
    ADD CONSTRAINT fk_rails_3cf221d4ed FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_groups
    ADD CONSTRAINT fk_rails_3d28377556 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.note_diff_files
    ADD CONSTRAINT fk_rails_3d66047aeb FOREIGN KEY (diff_note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.snippet_user_mentions
    ADD CONSTRAINT fk_rails_3e00189191 FOREIGN KEY (snippet_id) REFERENCES public.snippets(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_helm
    ADD CONSTRAINT fk_rails_3e2b1c06bc FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epic_user_mentions
    ADD CONSTRAINT fk_rails_3eaf4d88cc FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_cycle_analytics_project_stages
    ADD CONSTRAINT fk_rails_3ec9fd7912 FOREIGN KEY (end_event_label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_assignees
    ADD CONSTRAINT fk_rails_3f6f926bd5 FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.description_versions
    ADD CONSTRAINT fk_rails_3ff658220b FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_kubernetes_namespaces
    ADD CONSTRAINT fk_rails_40cc7ccbc3 FOREIGN KEY (cluster_project_id) REFERENCES public.cluster_projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_node_namespace_links
    ADD CONSTRAINT fk_rails_41ff5fb854 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epic_issues
    ADD CONSTRAINT fk_rails_4209981af6 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_refs
    ADD CONSTRAINT fk_rails_4249db8cc3 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_resources
    ADD CONSTRAINT fk_rails_430336af2d FOREIGN KEY (resource_group_id) REFERENCES public.ci_resource_groups(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_fluentd
    ADD CONSTRAINT fk_rails_4319b1dcd2 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_strategies_user_lists
    ADD CONSTRAINT fk_rails_43241e8d29 FOREIGN KEY (strategy_id) REFERENCES public.operations_strategies(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.lfs_file_locks
    ADD CONSTRAINT fk_rails_43df7a0412 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_assignees
    ADD CONSTRAINT fk_rails_443443ce6f FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_dependency_links
    ADD CONSTRAINT fk_rails_4437bf4070 FOREIGN KEY (dependency_id) REFERENCES public.packages_dependencies(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_auto_devops
    ADD CONSTRAINT fk_rails_45436b12b2 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests_closing_issues
    ADD CONSTRAINT fk_rails_458eda8667 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_environment_deploy_access_levels
    ADD CONSTRAINT fk_rails_45cc02a931 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.prometheus_alert_events
    ADD CONSTRAINT fk_rails_4675865839 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.smartcard_identities
    ADD CONSTRAINT fk_rails_4689f889a9 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT fk_rails_472f69b043 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_custom_attributes
    ADD CONSTRAINT fk_rails_47b91868a8 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_deletion_schedules
    ADD CONSTRAINT fk_rails_4b8c694a6c FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.design_management_designs
    ADD CONSTRAINT fk_rails_4bb1073360 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issue_metrics
    ADD CONSTRAINT fk_rails_4bb543d85d FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_metrics_settings
    ADD CONSTRAINT fk_rails_4c6037ee4f FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.prometheus_metrics
    ADD CONSTRAINT fk_rails_4c8957a707 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.scim_identities
    ADD CONSTRAINT fk_rails_4d2056ebd9 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.snippet_user_mentions
    ADD CONSTRAINT fk_rails_4d3f96b2cb FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployment_clusters
    ADD CONSTRAINT fk_rails_4e6243e120 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_repository_renamed_events
    ADD CONSTRAINT fk_rails_4e6524febb FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.aws_roles
    ADD CONSTRAINT fk_rails_4ed56f4720 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.security_scans
    ADD CONSTRAINT fk_rails_4ef1e6b4c6 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_diff_files
    ADD CONSTRAINT fk_rails_501aa0a391 FOREIGN KEY (merge_request_diff_id) REFERENCES public.merge_request_diffs(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.status_page_settings
    ADD CONSTRAINT fk_rails_506e5ba391 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_repository_storage_moves
    ADD CONSTRAINT fk_rails_5106dbd44a FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.x509_commit_signatures
    ADD CONSTRAINT fk_rails_53fe41188f FOREIGN KEY (x509_certificate_id) REFERENCES public.x509_certificates(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_node_namespace_links
    ADD CONSTRAINT fk_rails_546bf08d3e FOREIGN KEY (geo_node_id) REFERENCES public.geo_nodes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_knative
    ADD CONSTRAINT fk_rails_54fc91e0a0 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.terraform_states
    ADD CONSTRAINT fk_rails_558901b030 FOREIGN KEY (locked_by_user_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.group_deploy_keys
    ADD CONSTRAINT fk_rails_5682fc07f8 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.issue_user_mentions
    ADD CONSTRAINT fk_rails_57581fda73 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_assignees
    ADD CONSTRAINT fk_rails_579d375628 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_cycle_analytics_group_stages
    ADD CONSTRAINT fk_rails_5a22f40223 FOREIGN KEY (start_event_label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT fk_rails_5a7c055bdc FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_label_events
    ADD CONSTRAINT fk_rails_5ac1d2fc24 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rules_groups
    ADD CONSTRAINT fk_rails_5b2ecf6139 FOREIGN KEY (approval_merge_request_rule_id) REFERENCES public.approval_merge_request_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_environment_deploy_access_levels
    ADD CONSTRAINT fk_rails_5b9f6970fe FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_branch_unprotect_access_levels
    ADD CONSTRAINT fk_rails_5be1abfc25 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_providers_gcp
    ADD CONSTRAINT fk_rails_5c2c3bc814 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.insights
    ADD CONSTRAINT fk_rails_5c4391f60a FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_scanners
    ADD CONSTRAINT fk_rails_5c9d42a221 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_5ca11d8c31 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.epic_issues
    ADD CONSTRAINT fk_rails_5d942936b4 FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_weight_events
    ADD CONSTRAINT fk_rails_5eb5cb92a1 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules
    ADD CONSTRAINT fk_rails_5fb4dd100b FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_highest_roles
    ADD CONSTRAINT fk_rails_60f6c325a6 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.dependency_proxy_group_settings
    ADD CONSTRAINT fk_rails_616ddd680a FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_deploy_tokens
    ADD CONSTRAINT fk_rails_61a572b41a FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.status_page_published_incidents
    ADD CONSTRAINT fk_rails_61e5493940 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployment_clusters
    ADD CONSTRAINT fk_rails_6359a164df FOREIGN KEY (deployment_id) REFERENCES public.deployments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.evidences
    ADD CONSTRAINT fk_rails_6388b435a6 FOREIGN KEY (release_id) REFERENCES public.releases(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.jira_imports
    ADD CONSTRAINT fk_rails_63cbe52ada FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.group_deploy_tokens
    ADD CONSTRAINT fk_rails_6477b01f6b FOREIGN KEY (deploy_token_id) REFERENCES public.deploy_tokens(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_64798be025 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_feature_flags
    ADD CONSTRAINT fk_rails_648e241be7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_sources_projects
    ADD CONSTRAINT fk_rails_64b6855cbc FOREIGN KEY (source_project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_group_recent_visits
    ADD CONSTRAINT fk_rails_64bfc19bc5 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rule_sources
    ADD CONSTRAINT fk_rails_64e8ed3c7e FOREIGN KEY (approval_project_rule_id) REFERENCES public.approval_project_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipeline_chat_data
    ADD CONSTRAINT fk_rails_64ebfab6b3 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules_protected_branches
    ADD CONSTRAINT fk_rails_65203aa786 FOREIGN KEY (approval_project_rule_id) REFERENCES public.approval_project_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.design_management_versions
    ADD CONSTRAINT fk_rails_6574200d99 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rules_approved_approvers
    ADD CONSTRAINT fk_rails_6577725edb FOREIGN KEY (approval_merge_request_rule_id) REFERENCES public.approval_merge_request_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_feature_flags_clients
    ADD CONSTRAINT fk_rails_6650ed902c FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.web_hook_logs
    ADD CONSTRAINT fk_rails_666826e111 FOREIGN KEY (web_hook_id) REFERENCES public.web_hooks(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.jira_imports
    ADD CONSTRAINT fk_rails_675d38c03b FOREIGN KEY (label_id) REFERENCES public.labels(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.geo_hashed_storage_migrated_events
    ADD CONSTRAINT fk_rails_687ed7d7c5 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.plan_limits
    ADD CONSTRAINT fk_rails_69f8b6184f FOREIGN KEY (plan_id) REFERENCES public.plans(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_feature_flags_issues
    ADD CONSTRAINT fk_rails_6a8856ca4f FOREIGN KEY (feature_flag_id) REFERENCES public.operations_feature_flags(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.prometheus_alerts
    ADD CONSTRAINT fk_rails_6d9b283465 FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.term_agreements
    ADD CONSTRAINT fk_rails_6ea6520e4a FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_compliance_framework_settings
    ADD CONSTRAINT fk_rails_6f5294f16c FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users_security_dashboard_projects
    ADD CONSTRAINT fk_rails_6f6cf8e66e FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_builds_runner_session
    ADD CONSTRAINT fk_rails_70707857d3 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.list_user_preferences
    ADD CONSTRAINT fk_rails_70b2ef5ce2 FOREIGN KEY (list_id) REFERENCES public.lists(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_custom_attributes
    ADD CONSTRAINT fk_rails_719c3dccc5 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.slack_integrations
    ADD CONSTRAINT fk_rails_73db19721a FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_context_commit_diff_files
    ADD CONSTRAINT fk_rails_74a00a1787 FOREIGN KEY (merge_request_context_commit_id) REFERENCES public.merge_request_context_commits(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_ingress
    ADD CONSTRAINT fk_rails_753a7b41c1 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.release_links
    ADD CONSTRAINT fk_rails_753be7ae29 FOREIGN KEY (release_id) REFERENCES public.releases(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.milestone_releases
    ADD CONSTRAINT fk_rails_754f27dbfa FOREIGN KEY (release_id) REFERENCES public.releases(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_repositories_changed_events
    ADD CONSTRAINT fk_rails_75ec0fefcc FOREIGN KEY (geo_node_id) REFERENCES public.geo_nodes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_label_events
    ADD CONSTRAINT fk_rails_75efb0a653 FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.x509_certificates
    ADD CONSTRAINT fk_rails_76479fb5b4 FOREIGN KEY (x509_issuer_id) REFERENCES public.x509_issuers(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pages_domain_acme_orders
    ADD CONSTRAINT fk_rails_76581b1c16 FOREIGN KEY (pages_domain_id) REFERENCES public.pages_domains(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_subscriptions_projects
    ADD CONSTRAINT fk_rails_7871f9a97b FOREIGN KEY (upstream_project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.terraform_states
    ADD CONSTRAINT fk_rails_78f54ca485 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.software_license_policies
    ADD CONSTRAINT fk_rails_7a7a2a92de FOREIGN KEY (software_license_id) REFERENCES public.software_licenses(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_repositories
    ADD CONSTRAINT fk_rails_7a810d4121 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_scopes
    ADD CONSTRAINT fk_rails_7a9358853b FOREIGN KEY (strategy_id) REFERENCES public.operations_strategies(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.milestone_releases
    ADD CONSTRAINT fk_rails_7ae0756a2d FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT fk_rails_7e112a9599 FOREIGN KEY (instance_administration_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.clusters_kubernetes_namespaces
    ADD CONSTRAINT fk_rails_7e7688ecaf FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rules_users
    ADD CONSTRAINT fk_rails_80e6801803 FOREIGN KEY (approval_merge_request_rule_id) REFERENCES public.approval_merge_request_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployment_merge_requests
    ADD CONSTRAINT fk_rails_86a6d8bf12 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_language_trend_repository_languages
    ADD CONSTRAINT fk_rails_86cc9aef5f FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_crossplane
    ADD CONSTRAINT fk_rails_87186702df FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_runner_namespaces
    ADD CONSTRAINT fk_rails_8767676b7a FOREIGN KEY (runner_id) REFERENCES public.ci_runners(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.software_license_policies
    ADD CONSTRAINT fk_rails_87b2247ce5 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_environment_deploy_access_levels
    ADD CONSTRAINT fk_rails_898a13b650 FOREIGN KEY (protected_environment_id) REFERENCES public.protected_environments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.snippet_repositories
    ADD CONSTRAINT fk_rails_8afd7e2f71 FOREIGN KEY (snippet_id) REFERENCES public.snippets(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gpg_key_subkeys
    ADD CONSTRAINT fk_rails_8b2c90b046 FOREIGN KEY (gpg_key_id) REFERENCES public.gpg_keys(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_user_preferences
    ADD CONSTRAINT fk_rails_8b3b23ce82 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.allowed_email_domains
    ADD CONSTRAINT fk_rails_8b5da859f9 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_projects
    ADD CONSTRAINT fk_rails_8b8c5caf07 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_pages_metadata
    ADD CONSTRAINT fk_rails_8c28a61485 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_conan_metadata
    ADD CONSTRAINT fk_rails_8c68cfec8b FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT fk_rails_8c77e5891a FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.approval_merge_request_rules_approved_approvers
    ADD CONSTRAINT fk_rails_8dc94cff4d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.design_user_mentions
    ADD CONSTRAINT fk_rails_8de8c6d632 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_kubernetes_namespaces
    ADD CONSTRAINT fk_rails_8df789f3ab FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.alert_management_alert_user_mentions
    ADD CONSTRAINT fk_rails_8e48eca0fe FOREIGN KEY (alert_management_alert_id) REFERENCES public.alert_management_alerts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_daily_statistics
    ADD CONSTRAINT fk_rails_8e549b272d FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_pipelines_config
    ADD CONSTRAINT fk_rails_906c9a2533 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules_groups
    ADD CONSTRAINT fk_rails_9071e863d1 FOREIGN KEY (approval_project_rule_id) REFERENCES public.approval_project_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrences
    ADD CONSTRAINT fk_rails_90fed4faba FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_reset_checksum_events
    ADD CONSTRAINT fk_rails_910a06f12b FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_error_tracking_settings
    ADD CONSTRAINT fk_rails_910a2b8bd9 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.list_user_preferences
    ADD CONSTRAINT fk_rails_916d72cafd FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_labels
    ADD CONSTRAINT fk_rails_9374a16edd FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.alert_management_alert_assignees
    ADD CONSTRAINT fk_rails_93c0f6703b FOREIGN KEY (alert_id) REFERENCES public.alert_management_alerts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.scim_identities
    ADD CONSTRAINT fk_rails_9421a0bffb FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_pypi_metadata
    ADD CONSTRAINT fk_rails_9698717cdd FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_dependency_links
    ADD CONSTRAINT fk_rails_96ef1c00d3 FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_label_events
    ADD CONSTRAINT fk_rails_9851a00031 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_job_artifacts
    ADD CONSTRAINT fk_rails_9862d392f9 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_project_recent_visits
    ADD CONSTRAINT fk_rails_98f8843922 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_kubernetes_namespaces
    ADD CONSTRAINT fk_rails_98fe21e486 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.vulnerability_exports
    ADD CONSTRAINT fk_rails_9aff2c3b45 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users_ops_dashboard_projects
    ADD CONSTRAINT fk_rails_9b4ebf005b FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_incident_management_settings
    ADD CONSTRAINT fk_rails_9c2ea1b7dd FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gpg_keys
    ADD CONSTRAINT fk_rails_9d1f5d8719 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_language_trend_repository_languages
    ADD CONSTRAINT fk_rails_9d851d566c FOREIGN KEY (programming_language_id) REFERENCES public.programming_languages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT fk_rails_9df4a56538 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters_applications_cert_managers
    ADD CONSTRAINT fk_rails_9e4f2cb4b2 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_milestone_events
    ADD CONSTRAINT fk_rails_a006df5590 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.namespace_root_storage_statistics
    ADD CONSTRAINT fk_rails_a0702c430b FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_aliases
    ADD CONSTRAINT fk_rails_a1804f74a7 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_user_mentions
    ADD CONSTRAINT fk_rails_a18600f210 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT fk_rails_a27c483435 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.jira_tracker_data
    ADD CONSTRAINT fk_rails_a299066916 FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_environments
    ADD CONSTRAINT fk_rails_a354313d11 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.jira_connect_subscriptions
    ADD CONSTRAINT fk_rails_a3c10bcf7d FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.fork_network_members
    ADD CONSTRAINT fk_rails_a40860a1ca FOREIGN KEY (fork_network_id) REFERENCES public.fork_networks(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_feature_flag_scopes
    ADD CONSTRAINT fk_rails_a50a04d0a4 FOREIGN KEY (feature_flag_id) REFERENCES public.operations_feature_flags(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_projects
    ADD CONSTRAINT fk_rails_a5a958bca1 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.commit_user_mentions
    ADD CONSTRAINT fk_rails_a6760813e0 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_identifiers
    ADD CONSTRAINT fk_rails_a67a16c885 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT fk_rails_a69bfcfd81 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.sentry_issues
    ADD CONSTRAINT fk_rails_a6a9612965 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.repository_languages
    ADD CONSTRAINT fk_rails_a750ec87a8 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_milestone_events
    ADD CONSTRAINT fk_rails_a788026e85 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.term_agreements
    ADD CONSTRAINT fk_rails_a88721bcdf FOREIGN KEY (term_id) REFERENCES public.application_setting_terms(id);

ALTER TABLE ONLY public.merge_request_user_mentions
    ADD CONSTRAINT fk_rails_aa1b2961b1 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.x509_commit_signatures
    ADD CONSTRAINT fk_rails_ab07452314 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_trace_sections
    ADD CONSTRAINT fk_rails_ab7c104e26 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.clusters
    ADD CONSTRAINT fk_rails_ac3a663d79 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.packages_composer_metadata
    ADD CONSTRAINT fk_rails_ad48c2e5bb FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_cycle_analytics_group_stages
    ADD CONSTRAINT fk_rails_ae5da3409b FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.metrics_dashboard_annotations
    ADD CONSTRAINT fk_rails_aeb11a7643 FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pool_repositories
    ADD CONSTRAINT fk_rails_af3f8c5d62 FOREIGN KEY (shard_id) REFERENCES public.shards(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.resource_label_events
    ADD CONSTRAINT fk_rails_b126799f57 FOREIGN KEY (label_id) REFERENCES public.labels(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.packages_build_infos
    ADD CONSTRAINT fk_rails_b18868292d FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_trains
    ADD CONSTRAINT fk_rails_b29261ce31 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_project_recent_visits
    ADD CONSTRAINT fk_rails_b315dd0c80 FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues_prometheus_alert_events
    ADD CONSTRAINT fk_rails_b32edb790f FOREIGN KEY (prometheus_alert_event_id) REFERENCES public.prometheus_alert_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_trains
    ADD CONSTRAINT fk_rails_b374b5225d FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT fk_rails_b53e481273 FOREIGN KEY (custom_project_templates_group_id) REFERENCES public.namespaces(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.namespace_aggregation_schedules
    ADD CONSTRAINT fk_rails_b565c8d16c FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules_protected_branches
    ADD CONSTRAINT fk_rails_b7567b031b FOREIGN KEY (protected_branch_id) REFERENCES public.protected_branches(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.alerts_service_data
    ADD CONSTRAINT fk_rails_b93215a42c FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_trains
    ADD CONSTRAINT fk_rails_b9d67af01d FOREIGN KEY (target_project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules_users
    ADD CONSTRAINT fk_rails_b9e9394efb FOREIGN KEY (approval_project_rule_id) REFERENCES public.approval_project_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT fk_rails_baed5f39b7 FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rules_users
    ADD CONSTRAINT fk_rails_bc8972fa55 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.external_pull_requests
    ADD CONSTRAINT fk_rails_bcae9b5c7b FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.elasticsearch_indexed_projects
    ADD CONSTRAINT fk_rails_bd13bbdc3d FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.elasticsearch_indexed_namespaces
    ADD CONSTRAINT fk_rails_bdcf044f37 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrence_identifiers
    ADD CONSTRAINT fk_rails_be2e49e1d0 FOREIGN KEY (identifier_id) REFERENCES public.vulnerability_identifiers(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrences
    ADD CONSTRAINT fk_rails_bf5b788ca7 FOREIGN KEY (scanner_id) REFERENCES public.vulnerability_scanners(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_weight_events
    ADD CONSTRAINT fk_rails_bfc406b47c FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.design_management_designs
    ADD CONSTRAINT fk_rails_bfe283ec3c FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.serverless_domain_cluster
    ADD CONSTRAINT fk_rails_c09009dee1 FOREIGN KEY (pages_domain_id) REFERENCES public.pages_domains(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT fk_rails_c1ac5161d8 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_feature_usages
    ADD CONSTRAINT fk_rails_c22a50024b FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_canonical_emails
    ADD CONSTRAINT fk_rails_c2bd828b51 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_repositories
    ADD CONSTRAINT fk_rails_c3258dc63b FOREIGN KEY (shard_id) REFERENCES public.shards(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.packages_nuget_dependency_link_metadata
    ADD CONSTRAINT fk_rails_c3313ee2e4 FOREIGN KEY (dependency_link_id) REFERENCES public.packages_dependency_links(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_user_mentions
    ADD CONSTRAINT fk_rails_c440b9ea31 FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_job_artifacts
    ADD CONSTRAINT fk_rails_c5137cb2c1 FOREIGN KEY (job_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_settings
    ADD CONSTRAINT fk_rails_c6df6e6328 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.container_expiration_policies
    ADD CONSTRAINT fk_rails_c7360f09ad FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.wiki_page_meta
    ADD CONSTRAINT fk_rails_c7a0c59cf1 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.scim_oauth_access_tokens
    ADD CONSTRAINT fk_rails_c84404fb6c FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrences
    ADD CONSTRAINT fk_rails_c8661a61eb FOREIGN KEY (primary_identifier_id) REFERENCES public.vulnerability_identifiers(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_export_jobs
    ADD CONSTRAINT fk_rails_c88d8db2e1 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_state_events
    ADD CONSTRAINT fk_rails_c913c64977 FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_milestone_events
    ADD CONSTRAINT fk_rails_c940fb9fc5 FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.gpg_signatures
    ADD CONSTRAINT fk_rails_c97176f5f7 FOREIGN KEY (gpg_key_id) REFERENCES public.gpg_keys(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.board_group_recent_visits
    ADD CONSTRAINT fk_rails_ca04c38720 FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_daily_report_results
    ADD CONSTRAINT fk_rails_cc5caec7d9 FOREIGN KEY (last_pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues_self_managed_prometheus_alert_events
    ADD CONSTRAINT fk_rails_cc5d88bbb0 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_strategies_user_lists
    ADD CONSTRAINT fk_rails_ccb7e4bc0b FOREIGN KEY (user_list_id) REFERENCES public.operations_user_lists(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issue_tracker_data
    ADD CONSTRAINT fk_rails_ccc0840427 FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_milestone_events
    ADD CONSTRAINT fk_rails_cedf8cce4d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.epic_metrics
    ADD CONSTRAINT fk_rails_d071904753 FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_d0c8bda804 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_strategies
    ADD CONSTRAINT fk_rails_d183b6e6dd FOREIGN KEY (feature_flag_id) REFERENCES public.operations_feature_flags(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requirements_management_test_reports
    ADD CONSTRAINT fk_rails_d1e8b498bf FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.pool_repositories
    ADD CONSTRAINT fk_rails_d2711daad4 FOREIGN KEY (source_project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.group_group_links
    ADD CONSTRAINT fk_rails_d3a0488427 FOREIGN KEY (shared_group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_issue_links
    ADD CONSTRAINT fk_rails_d459c19036 FOREIGN KEY (vulnerability_id) REFERENCES public.vulnerabilities(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.alert_management_alert_assignees
    ADD CONSTRAINT fk_rails_d47570ac62 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.geo_hashed_storage_attachments_events
    ADD CONSTRAINT fk_rails_d496b088e9 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.jira_imports
    ADD CONSTRAINT fk_rails_da617096ce FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.dependency_proxy_blobs
    ADD CONSTRAINT fk_rails_db58bbc5d7 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues_prometheus_alert_events
    ADD CONSTRAINT fk_rails_db5b756534 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_user_preferences
    ADD CONSTRAINT fk_rails_dbebdaa8fe FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_dc3ae04693 FOREIGN KEY (occurrence_id) REFERENCES public.vulnerability_occurrences(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.deployment_merge_requests
    ADD CONSTRAINT fk_rails_dcbce9f4df FOREIGN KEY (deployment_id) REFERENCES public.deployments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_callouts
    ADD CONSTRAINT fk_rails_ddfdd80f3d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_feedback
    ADD CONSTRAINT fk_rails_debd54e456 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.analytics_cycle_analytics_group_stages
    ADD CONSTRAINT fk_rails_dfb37c880d FOREIGN KEY (end_event_label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.label_priorities
    ADD CONSTRAINT fk_rails_e161058b0f FOREIGN KEY (label_id) REFERENCES public.labels(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_packages
    ADD CONSTRAINT fk_rails_e1ac527425 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_platforms_kubernetes
    ADD CONSTRAINT fk_rails_e1e2cf841a FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_builds_metadata
    ADD CONSTRAINT fk_rails_e20479742e FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_occurrence_identifiers
    ADD CONSTRAINT fk_rails_e4ef6d027c FOREIGN KEY (occurrence_id) REFERENCES public.vulnerability_occurrences(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.serverless_domain_cluster
    ADD CONSTRAINT fk_rails_e59e868733 FOREIGN KEY (clusters_applications_knative_id) REFERENCES public.clusters_applications_knative(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_merge_request_rule_sources
    ADD CONSTRAINT fk_rails_e605a04f76 FOREIGN KEY (approval_merge_request_rule_id) REFERENCES public.approval_merge_request_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.prometheus_alerts
    ADD CONSTRAINT fk_rails_e6351447ec FOREIGN KEY (prometheus_metric_id) REFERENCES public.prometheus_metrics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requirements_management_test_reports
    ADD CONSTRAINT fk_rails_e67d085910 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.merge_request_metrics
    ADD CONSTRAINT fk_rails_e6d7c24d1b FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.draft_notes
    ADD CONSTRAINT fk_rails_e753681674 FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.description_versions
    ADD CONSTRAINT fk_rails_e8f4caf9c7 FOREIGN KEY (epic_id) REFERENCES public.epics(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vulnerability_issue_links
    ADD CONSTRAINT fk_rails_e9180d534b FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_request_blocks
    ADD CONSTRAINT fk_rails_e9387863bc FOREIGN KEY (blocking_merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.protected_branch_unprotect_access_levels
    ADD CONSTRAINT fk_rails_e9eb8dc025 FOREIGN KEY (protected_branch_id) REFERENCES public.protected_branches(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.alert_management_alert_user_mentions
    ADD CONSTRAINT fk_rails_eb2de0cdef FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_daily_report_results
    ADD CONSTRAINT fk_rails_ebc2931b90 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_providers_aws
    ADD CONSTRAINT fk_rails_ed1fdfaeb2 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.project_security_settings
    ADD CONSTRAINT fk_rails_ed4abe1338 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_daily_build_group_report_results
    ADD CONSTRAINT fk_rails_ee072d13b3 FOREIGN KEY (last_pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.label_priorities
    ADD CONSTRAINT fk_rails_ef916d14fa FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.fork_network_members
    ADD CONSTRAINT fk_rails_efccadc4ec FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.prometheus_alerts
    ADD CONSTRAINT fk_rails_f0e8db86aa FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.import_export_uploads
    ADD CONSTRAINT fk_rails_f129140f9e FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.jira_connect_subscriptions
    ADD CONSTRAINT fk_rails_f1d617343f FOREIGN KEY (jira_connect_installation_id) REFERENCES public.jira_connect_installations(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT fk_rails_f212e67e63 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.snippet_repositories
    ADD CONSTRAINT fk_rails_f21f899728 FOREIGN KEY (shard_id) REFERENCES public.shards(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.ci_pipeline_chat_data
    ADD CONSTRAINT fk_rails_f300456b63 FOREIGN KEY (chat_name_id) REFERENCES public.chat_names(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.approval_project_rules_users
    ADD CONSTRAINT fk_rails_f365da8250 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.insights
    ADD CONSTRAINT fk_rails_f36fda3932 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_group_recent_visits
    ADD CONSTRAINT fk_rails_f410736518 FOREIGN KEY (group_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_state_events
    ADD CONSTRAINT fk_rails_f5827a7ccd FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.design_user_mentions
    ADD CONSTRAINT fk_rails_f7075a53c1 FOREIGN KEY (design_id) REFERENCES public.design_management_designs(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.internal_ids
    ADD CONSTRAINT fk_rails_f7d46b66c6 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.issues_self_managed_prometheus_alert_events
    ADD CONSTRAINT fk_rails_f7db2d72eb FOREIGN KEY (self_managed_prometheus_alert_event_id) REFERENCES public.self_managed_prometheus_alert_events(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_requests_closing_issues
    ADD CONSTRAINT fk_rails_f8540692be FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ci_build_trace_section_names
    ADD CONSTRAINT fk_rails_f8cd72cd26 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merge_trains
    ADD CONSTRAINT fk_rails_f90820cb08 FOREIGN KEY (pipeline_id) REFERENCES public.ci_pipelines(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_runner_namespaces
    ADD CONSTRAINT fk_rails_f9d9ed3308 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requirements_management_test_reports
    ADD CONSTRAINT fk_rails_fb3308ad55 FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.operations_feature_flags_issues
    ADD CONSTRAINT fk_rails_fb4d2a7cb1 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.board_project_recent_visits
    ADD CONSTRAINT fk_rails_fb6fc419cb FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.serverless_domain_cluster
    ADD CONSTRAINT fk_rails_fbdba67eb1 FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_job_variables
    ADD CONSTRAINT fk_rails_fbf3b34792 FOREIGN KEY (job_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.packages_nuget_metadata
    ADD CONSTRAINT fk_rails_fc0c19f5b4 FOREIGN KEY (package_id) REFERENCES public.packages_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.cluster_groups
    ADD CONSTRAINT fk_rails_fdb8648a96 FOREIGN KEY (cluster_id) REFERENCES public.clusters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.project_tracing_settings
    ADD CONSTRAINT fk_rails_fe56f57fc6 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resource_label_events
    ADD CONSTRAINT fk_rails_fe91ece594 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ci_builds_metadata
    ADD CONSTRAINT fk_rails_ffcf702a02 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.timelogs
    ADD CONSTRAINT fk_timelogs_issues_issue_id FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.timelogs
    ADD CONSTRAINT fk_timelogs_merge_requests_merge_request_id FOREIGN KEY (merge_request_id) REFERENCES public.merge_requests(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.u2f_registrations
    ADD CONSTRAINT fk_u2f_registrations_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

COPY "schema_migrations" (version) FROM STDIN;
20181228175414
20190102152410
20190103140724
20190104182041
20190107151020
20190108192941
20190109153125
20190114172110
20190115054215
20190115054216
20190115092821
20190116234221
20190124200344
20190130091630
20190131122559
20190204115450
20190206193120
20190211131150
20190214112022
20190215154930
20190218134158
20190218134209
20190219201635
20190220142344
20190220150130
20190222051615
20190225152525
20190225160300
20190225160301
20190228192410
20190301081611
20190301182457
20190312071108
20190312113229
20190312113634
20190313092516
20190315191339
20190320174702
20190322132835
20190322164830
20190325080727
20190325105715
20190325111602
20190325165127
20190326164045
20190327163904
20190329085614
20190402150158
20190402224749
20190403161806
20190404143330
20190404231137
20190408163745
20190409224933
20190410173409
20190412155659
20190412183653
20190414185432
20190415030217
20190415095825
20190415172035
20190416185130
20190416213556
20190416213615
20190416213631
20190418132125
20190418132750
20190418182545
20190419121952
20190419123057
20190422082247
20190423124640
20190424134256
20190426180107
20190429082448
20190430131225
20190430142025
20190506135337
20190506135400
20190511144331
20190513174947
20190514105711
20190515125613
20190516011213
20190516151857
20190516155724
20190517153211
20190520200123
20190520201748
20190521174505
20190522143720
20190523112344
20190524062810
20190524071727
20190524073827
20190527011309
20190527194830
20190527194900
20190528173628
20190528180441
20190529142545
20190530042141
20190530154715
20190531153110
20190602014139
20190603124955
20190604091310
20190604184643
20190605104727
20190605184422
20190606014128
20190606034427
20190606054649
20190606054742
20190606054832
20190606163724
20190606175050
20190606202100
20190607085356
20190607145325
20190607190856
20190607205656
20190610142825
20190611090827
20190611100201
20190611100202
20190611161641
20190611161642
20190612111201
20190612111404
20190613030606
20190613044655
20190613073003
20190613231640
20190617123615
20190618171120
20190619175843
20190620105427
20190620112608
20190621022810
20190621151636
20190623212503
20190624123615
20190625115224
20190625184066
20190626175626
20190627051902
20190627100221
20190627122264
20190628145246
20190628185000
20190628185004
20190628191740
20190702173936
20190703043358
20190703130053
20190703171157
20190703171555
20190703185326
20190709204413
20190709220014
20190709220143
20190710151229
20190711124721
20190711200053
20190711200508
20190711201818
20190712040400
20190712040412
20190712064021
20190715042813
20190715043944
20190715043954
20190715044501
20190715114644
20190715140740
20190715142138
20190715173819
20190715193142
20190715215532
20190715215549
20190716144222
20190719122333
20190719174505
20190722104947
20190722132830
20190722144316
20190723105753
20190723153247
20190724112147
20190725012225
20190725080128
20190725183432
20190726101050
20190726101133
20190729062536
20190729090456
20190729180447
20190731084415
20190801060809
20190801114109
20190801142441
20190801193427
20190802012622
20190802091750
20190802195602
20190802235445
20190805140353
20190806071559
20190807023052
20190808152507
20190809072552
20190812070645
20190814205640
20190815093936
20190815093949
20190816151221
20190819131155
20190819231552
20190820163320
20190821040941
20190822175441
20190822181528
20190822185441
20190823055948
20190826090628
20190826100605
20190827102026
20190827222124
20190828083843
20190828110802
20190828170945
20190828172831
20190829131130
20190830075508
20190830080123
20190830080626
20190830140240
20190901174200
20190902131045
20190902152329
20190902160015
20190903150358
20190903150435
20190904173203
20190904205212
20190905022045
20190905074652
20190905091812
20190905091831
20190905140605
20190905223800
20190905223900
20190906104555
20190907184714
20190909045845
20190909141517
20190910000130
20190910103144
20190910114843
20190910125852
20190910211526
20190910212256
20190911115056
20190911115109
20190911115207
20190911115222
20190911251732
20190912061145
20190912223232
20190913174707
20190913175827
20190914223900
20190917173107
20190918025618
20190918102042
20190918104212
20190918104222
20190918104731
20190918121135
20190919040324
20190919091300
20190919104119
20190919162036
20190919183411
20190920122420
20190920194925
20190920224341
20190924124627
20190924152703
20190925055714
20190925055902
20190926041216
20190926180443
20190926225633
20190927055500
20190927055540
20190927074328
20190929180751
20190929180813
20190929180827
20190930025655
20190930063627
20190930082942
20190930153535
20191001040549
20191001170300
20191002031332
20191002123516
20191003015155
20191003060227
20191003064615
20191003130045
20191003150045
20191003161031
20191003161032
20191003195218
20191003195620
20191003200045
20191003250045
20191003300045
20191003350045
20191004080818
20191004081520
20191004133612
20191004151428
20191007163701
20191007163736
20191008013056
20191008142331
20191008143850
20191008180203
20191008200204
20191009100244
20191009110124
20191009110757
20191009222222
20191010174846
20191011084019
20191013100213
20191014025629
20191014030134
20191014030730
20191014084150
20191014123159
20191014132931
20191015154408
20191016072826
20191016133352
20191016220135
20191017001326
20191017045817
20191017094449
20191017134513
20191017180026
20191017191341
20191021101942
20191022113635
20191023093207
20191023132005
20191023152913
20191024134020
20191025092748
20191026041447
20191026120008
20191026120112
20191026124116
20191028130054
20191028162543
20191028184740
20191029095537
20191029125305
20191029191901
20191030135044
20191030152934
20191030193050
20191030223057
20191031095636
20191031112603
20191101092917
20191103202505
20191104142124
20191104205020
20191105094558
20191105094625
20191105134413
20191105140942
20191105155113
20191105193652
20191106144901
20191106150931
20191107064946
20191107173446
20191107220314
20191108031900
20191108202723
20191111115229
20191111115431
20191111121500
20191111165017
20191111175230
20191112023159
20191112090226
20191112105448
20191112115247
20191112115317
20191112214305
20191112221821
20191112232338
20191114132259
20191114173508
20191114173602
20191114173624
20191114201118
20191114204343
20191115001123
20191115001843
20191115091425
20191115114032
20191115115043
20191115115522
20191118053631
20191118155702
20191118173522
20191118182722
20191118211629
20191119023952
20191119220425
20191119221041
20191119231621
20191120084627
20191120115530
20191120200015
20191121111621
20191121121947
20191121122856
20191121161018
20191121193110
20191122135327
20191122161519
20191123062354
20191123081456
20191124150431
20191125024005
20191125114345
20191125133353
20191125140458
20191126134210
20191127030005
20191127151619
20191127151629
20191127163053
20191127221608
20191128145231
20191128145232
20191128145233
20191128162854
20191129134844
20191129144630
20191129144631
20191202031812
20191202181924
20191203121729
20191204070713
20191204093410
20191204114127
20191204192726
20191205060723
20191205084057
20191205094702
20191205145647
20191205212923
20191205212924
20191206014412
20191206022133
20191206122926
20191207104000
20191208071111
20191208071112
20191208110214
20191209143606
20191209215316
20191210211253
20191212140117
20191212162434
20191213104838
20191213120427
20191213143656
20191213184609
20191214175727
20191216074800
20191216074802
20191216074803
20191216094119
20191216183531
20191216183532
20191217165641
20191217212348
20191218084115
20191218122457
20191218124915
20191218125015
20191218190253
20191218225624
20191223124940
20191225071320
20191227140254
20191229140154
20200102140148
20200102170221
20200103190741
20200103192859
20200103192914
20200103195205
20200104113850
20200106071113
20200106085831
20200107172020
20200108100603
20200108155731
20200108233040
20200109030418
20200109085206
20200109233938
20200110089001
20200110090153
20200110121314
20200110144316
20200110203532
20200113133352
20200113151354
20200114112932
20200114113341
20200114140305
20200114204949
20200115135132
20200115135234
20200116051619
20200116175538
20200117112554
20200117194830
20200117194840
20200117194850
20200117194900
20200120083607
20200121132641
20200121192942
20200121194000
20200121194048
20200121194154
20200121200203
20200122123016
20200122144759
20200122161638
20200123040535
20200123045415
20200123090839
20200123091422
20200123091622
20200123091734
20200123091854
20200123155929
20200124053531
20200124110831
20200124143014
20200127090233
20200127111840
20200128105731
20200128132510
20200128133510
20200128134110
20200128141125
20200128184209
20200128210353
20200129034515
20200129035446
20200129035708
20200129133716
20200129172428
20200130134335
20200130145430
20200130161817
20200131140428
20200131181354
20200131191754
20200202100932
20200203015140
20200203025400
20200203025602
20200203025619
20200203025744
20200203025801
20200203025821
20200203104214
20200203173508
20200203183508
20200203232433
20200204070729
20200204113223
20200204113224
20200204113225
20200204131054
20200204131831
20200205143231
20200206091544
20200206112850
20200206135203
20200206141511
20200207062728
20200207090921
20200207132752
20200207151640
20200207182131
20200207184023
20200207185149
20200209131152
20200210062432
20200210092405
20200210135504
20200210184410
20200210184420
20200211152410
20200211155000
20200211155100
20200211155539
20200211174946
20200212014653
20200212052620
20200212133945
20200212134201
20200213093702
20200213100530
20200213155311
20200213204737
20200213220159
20200213220211
20200213224220
20200214025454
20200214034836
20200214085940
20200214214934
20200215222507
20200215225103
20200217210353
20200217223651
20200217225719
20200218113721
20200219105209
20200219133859
20200219135440
20200219141307
20200219142522
20200219183456
20200219184219
20200219193058
20200219193117
20200220115023
20200220180944
20200221023320
20200221074028
20200221100514
20200221105436
20200221142216
20200221144534
20200222055543
20200224020219
20200224163804
20200224185814
20200225111018
20200225123228
20200226100614
20200226100624
20200226100634
20200226124757
20200226162156
20200226162239
20200226162634
20200226162723
20200227140242
20200227164113
20200227165129
20200228160542
20200302142052
20200302152516
20200303055348
20200303074328
20200303181648
20200304023245
20200304023851
20200304024025
20200304024042
20200304085423
20200304090155
20200304121828
20200304121844
20200304124406
20200304160800
20200304160801
20200304160823
20200304211738
20200305121159
20200305151736
20200305200641
20200306095654
20200306160521
20200306170211
20200306170321
20200306170531
20200306192548
20200306193236
20200309140540
20200309162244
20200309195209
20200309195710
20200310075115
20200310123229
20200310132654
20200310133822
20200310135818
20200310135823
20200310145304
20200310215714
20200311074438
20200311082301
20200311084025
20200311093210
20200311094020
20200311130802
20200311141053
20200311141943
20200311154110
20200311165635
20200311192351
20200311214912
20200312053852
20200312125121
20200312134637
20200312160532
20200312163407
20200313101649
20200313123934
20200313202430
20200313203525
20200313203550
20200313204021
20200314060834
20200316111759
20200316162648
20200316173312
20200317110602
20200317142110
20200318140400
20200318152134
20200318162148
20200318163148
20200318164448
20200318165448
20200318175008
20200318183553
20200319071702
20200319123041
20200319124127
20200319203901
20200320112455
20200320123839
20200320212400
20200323011225
20200323011955
20200323071918
20200323074147
20200323075043
20200323080714
20200323122201
20200323134519
20200324093258
20200324115359
20200325094612
20200325104755
20200325104756
20200325104833
20200325104834
20200325111432
20200325152327
20200325160952
20200325162730
20200325183636
20200326114443
20200326122700
20200326124443
20200326134443
20200326135443
20200326144443
20200326145443
20200330074719
20200330121000
20200330123739
20200330132913
20200330203826
20200330203837
20200331103637
20200331113728
20200331113738
20200331132103
20200331195952
20200331220930
20200401091051
20200401095430
20200401211005
20200402001106
20200402115013
20200402115623
20200402123926
20200402124802
20200402135250
20200402185044
20200403132349
20200403184110
20200403185127
20200403185422
20200406095930
20200406100909
20200406102111
20200406102120
20200406132529
20200406135648
20200406141452
20200406192059
20200406193427
20200407094005
20200407094923
20200407120000
20200407121321
20200407171133
20200407171417
20200407182205
20200407222647
20200408110856
20200408125046
20200408132152
20200408133211
20200408153842
20200408154331
20200408154349
20200408154411
20200408154428
20200408154455
20200408154533
20200408154604
20200408154624
20200408175424
20200408212219
20200409085956
20200409105455
20200409105456
20200409211607
20200410104828
20200410232012
20200411125656
20200413072059
20200413230056
20200414112444
20200414114611
20200414115801
20200414144547
20200415153154
20200415160722
20200415161021
20200415161206
20200415192656
20200415203024
20200416005331
20200416111111
20200416120128
20200416120354
20200417044453
20200417075843
20200417145946
20200420092011
20200420094444
20200420104303
20200420104323
20200420115948
20200420141733
20200420162730
20200420172113
20200420172752
20200420172927
20200420201933
20200421054930
20200421054948
20200421092907
20200421111005
20200421195234
20200421233150
20200422091541
20200422213749
20200423075720
20200423080334
20200423080607
20200423081409
20200423081441
20200423081519
20200423101529
20200424043515
20200424050250
20200424101920
20200424135319
20200427064130
20200428134356
20200429001827
20200429002150
20200429015603
20200429023324
20200429181335
20200429181955
20200429182245
20200430103158
20200430130048
20200430174637
20200505164958
20200505171834
20200505172405
20200506085748
20200506125731
20200506154421
20200507221434
20200508021128
20200508050301
20200508091106
20200508140959
20200508203901
20200511080113
20200511083541
20200511092246
20200511092505
20200511092714
20200511115430
20200511115431
20200511121549
20200511121610
20200511121620
20200511130129
20200511130130
20200511145545
20200511162057
20200511162115
20200511181027
20200511191027
20200511208012
20200511220023
20200512085150
20200512160004
20200512164334
20200512195442
20200513160930
20200513171959
20200513224143
20200513234502
20200513235347
20200513235532
20200514000009
20200514000132
20200514000340
20200515155620
20200518091745
20200518114540
20200518133123
20200519074709
20200519101002
20200519115908
20200519141534
20200519171058
20200519194042
20200520103514
20200521022725
20200521225327
20200521225337
20200521225346
20200522235146
20200525114553
20200525121014
20200525144525
20200526000407
20200526013844
20200526120714
20200526142550
20200526153844
20200526164946
20200526164947
20200527092027
20200527094322
20200527095401
20200527135313
20200527151413
20200527152116
20200527152657
20200527170649
20200527211000
20200528054112
20200528123703
20200528125905
20200528171933
20200601210148
20200602013900
20200602013901
20200603073101
20200603180338
20200604143628
20200604145731
20200604174544
20200604174558
20200605003204
20200608072931
20200608075553
20200608214008
20200609002841
20200609142506
20200609142507
20200609142508
20200609212701
20200615083635
\.

