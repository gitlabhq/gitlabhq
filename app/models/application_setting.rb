# frozen_string_literal: true

class ApplicationSetting < ApplicationRecord
  include CacheableAttributes
  include CacheMarkdownField
  include TokenAuthenticatable
  include ChronicDurationAttribute
  include Sanitizable

  ignore_columns %i[
    cloud_connector_keys
    encrypted_openai_api_key
    encrypted_openai_api_key_iv
    encrypted_anthropic_api_key
    encrypted_anthropic_api_key_iv
    encrypted_vertex_ai_credentials
    encrypted_vertex_ai_credentials_iv
    encrypted_vertex_ai_access_token
    encrypted_vertex_ai_access_token_iv
  ], remove_with: '17.10', remove_after: '2025-02-15'

  ignore_column :pre_receive_secret_detection_enabled, remove_with: '17.9', remove_after: '2025-02-15'

  ignore_columns %i[
    elasticsearch_aws
    elasticsearch_search
    elasticsearch_indexing
    elasticsearch_username
    elasticsearch_aws_region
    elasticsearch_aws_access_key
    elasticsearch_limit_indexing
    elasticsearch_pause_indexing
    elasticsearch_requeue_workers
    elasticsearch_max_bulk_size_mb
    elasticsearch_retry_on_failure
    elasticsearch_max_bulk_concurrency
    elasticsearch_client_request_timeout
    elasticsearch_worker_number_of_shards
    elasticsearch_analyzers_smartcn_search
    elasticsearch_analyzers_kuromoji_search
    elasticsearch_analyzers_smartcn_enabled
    elasticsearch_analyzers_kuromoji_enabled
    elasticsearch_indexed_field_length_limit
    elasticsearch_indexed_file_size_limit_kb
    elasticsearch_max_code_indexing_concurrency
    security_policy_scheduled_scans_max_concurrency
  ], remove_with: '17.11', remove_after: '2025-04-17'

  INSTANCE_REVIEW_MIN_USERS = 50
  GRAFANA_URL_ERROR_MESSAGE = 'Please check your Grafana URL setting in ' \
    'Admin area > Settings > Metrics and profiling > Metrics - Grafana'

  KROKI_URL_ERROR_MESSAGE = 'Please check your Kroki URL setting in ' \
    'Admin area > Settings > General > Kroki'

  # Validate URIs in this model according to the current value of the `deny_all_requests_except_allowed` property,
  # rather than the persisted value.
  ADDRESSABLE_URL_VALIDATION_OPTIONS = {
    deny_all_requests_except_allowed: ->(settings) do
      settings.deny_all_requests_except_allowed
    end
  }.freeze

  HUMANIZED_ATTRIBUTES = {
    archive_builds_in_seconds: 'Archive job value'
  }.freeze

  # matches the size set in the database constraint
  DEFAULT_BRANCH_PROTECTIONS_DEFAULT_MAX_SIZE = 1.kilobyte

  PACKAGE_REGISTRY_SETTINGS = [:nuget_skip_metadata_url_validation].freeze

  USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS = 3

  INACTIVE_RESOURCE_ACCESS_TOKENS_DELETE_AFTER_DAYS = 30

  enum :whats_new_variant, { all_tiers: 0, current_tier: 1, disabled: 2 }, prefix: true
  enum :email_confirmation_setting, { off: 0, soft: 1, hard: 2 }, prefix: true

  # We won't add a prefix here as this token is deprecated and being
  # disabled in 17.0
  # https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
  add_authentication_token_field :runners_registration_token, encrypted: :required
  add_authentication_token_field :health_check_access_token # rubocop:todo -- https://gitlab.com/gitlab-org/gitlab/-/issues/376751
  add_authentication_token_field :static_objects_external_storage_auth_token, encrypted: :required # rubocop:todo -- https://gitlab.com/gitlab-org/gitlab/-/issues/439292
  add_authentication_token_field :error_tracking_access_token, encrypted: :required # rubocop:todo -- https://gitlab.com/gitlab-org/gitlab/-/issues/439292

  belongs_to :push_rule
  belongs_to :web_ide_oauth_application, class_name: 'Doorkeeper::Application'

  alias_attribute :housekeeping_optimize_repository_period, :housekeeping_incremental_repack_period

  sanitizes! :default_branch_name

  def self.kroki_formats_attributes
    {
      blockdiag: {
        label: 'BlockDiag (includes BlockDiag, SeqDiag, ActDiag, NwDiag, PacketDiag, and RackDiag)'
      },
      bpmn: {
        label: 'BPMN'
      },
      excalidraw: {
        label: 'Excalidraw'
      }
    }
  end

  store_accessor :kroki_formats, *ApplicationSetting.kroki_formats_attributes.keys, prefix: true

  # Include here so it can override methods from
  # `add_authentication_token_field`
  # We don't prepend for now because otherwise we'll need to
  # fix a lot of tests using allow_any_instance_of
  include ApplicationSettingImplementation

  serialize :restricted_visibility_levels # rubocop:disable Cop/ActiveRecordSerialize
  serialize :import_sources # rubocop:disable Cop/ActiveRecordSerialize
  serialize :disabled_oauth_sign_in_sources, Array # rubocop:disable Cop/ActiveRecordSerialize
  serialize :domain_allowlist, Array # rubocop:disable Cop/ActiveRecordSerialize
  serialize :domain_denylist, Array # rubocop:disable Cop/ActiveRecordSerialize

  # See https://gitlab.com/gitlab-org/gitlab/-/issues/300916
  serialize :asset_proxy_allowlist, Array # rubocop:disable Cop/ActiveRecordSerialize
  serialize :asset_proxy_whitelist, Array # rubocop:disable Cop/ActiveRecordSerialize

  cache_markdown_field :help_page_text
  cache_markdown_field :shared_runners_text, pipeline: :plain_markdown
  cache_markdown_field :after_sign_up_text

  attribute :id, default: 1
  attribute :repository_storages_weighted, default: -> { {} }
  attribute :kroki_formats, default: -> { {} }
  attribute :default_branch_protection_defaults, default: -> { {} }

  chronic_duration_attr_writer :archive_builds_in_human_readable, :archive_builds_in_seconds

  chronic_duration_attr :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval
  chronic_duration_attr :group_runner_token_expiration_interval_human_readable, :group_runner_token_expiration_interval
  chronic_duration_attr :project_runner_token_expiration_interval_human_readable,
    :project_runner_token_expiration_interval

  validates :default_branch_protection_defaults, json_schema: { filename: 'default_branch_protection_defaults' }
  validates :default_branch_protection_defaults, bytesize: { maximum: -> {
    DEFAULT_BRANCH_PROTECTIONS_DEFAULT_MAX_SIZE
  } }

  validates :external_pipeline_validation_service_timeout,
    :failed_login_attempts_unlock_period_in_minutes,
    :max_login_attempts,
    allow_nil: true,
    numericality: { only_integer: true, greater_than: 0 }

  validates :grafana_url,
    system_hook_url: ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({
      blocked_message: "is blocked: %{exception_message}. #{GRAFANA_URL_ERROR_MESSAGE}"
    }),
    if: :grafana_url_absolute?

  validate :validate_grafana_url

  validates :uuid, presence: true

  validates :outbound_local_requests_whitelist,
    length: { maximum: 1_000, message: N_('is too long (maximum is 1000 entries)') },
    allow_nil: false,
    qualified_domain_array: true

  validates :minimum_password_length,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: DEFAULT_MINIMUM_PASSWORD_LENGTH,
      less_than_or_equal_to: Devise.password_length.max
    }

  validates :home_page_url,
    allow_blank: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS,
    if: :home_page_url_column_exists?

  validates :help_page_support_url,
    allow_blank: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS,
    if: :help_page_support_url_column_exists?

  validates :help_page_documentation_base_url,
    length: { maximum: 255, message: N_("is too long (maximum is %{count} characters)") },
    allow_blank: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS

  validates :after_sign_out_path,
    allow_blank: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS

  validates :abuse_notification_email,
    devise_email: true,
    allow_blank: true

  validates :two_factor_grace_period,
    numericality: { greater_than_or_equal_to: 0 }

  validates :recaptcha_site_key,
    presence: true,
    if: :recaptcha_or_login_protection_enabled

  validates :recaptcha_private_key,
    presence: true,
    if: :recaptcha_or_login_protection_enabled

  validates :akismet_api_key,
    presence: true,
    if: :akismet_enabled

  validates :spam_check_api_key,
    length: { maximum: 2000, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true

  validates :unique_ips_limit_per_user,
    numericality: { greater_than_or_equal_to: 1 },
    presence: true,
    if: :unique_ips_limit_enabled

  validates :unique_ips_limit_time_window,
    numericality: { greater_than_or_equal_to: 0 },
    presence: true,
    if: :unique_ips_limit_enabled

  validates :kroki_url, presence: { if: :kroki_enabled }

  validate :validate_kroki_url, if: :kroki_enabled

  validates :kroki_formats, json_schema: { filename: 'application_setting_kroki_formats' }

  validates :metrics_method_call_threshold,
    numericality: { greater_than_or_equal_to: 0 },
    presence: true,
    if: :prometheus_metrics_enabled

  validates :plantuml_url, presence: true, if: :plantuml_enabled

  validates :sourcegraph_url, presence: true, if: :sourcegraph_enabled

  validates :diagramsnet_url,
    presence: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({ enforce_sanitization: true }),
    if: :diagramsnet_enabled

  validates :gitpod_url,
    presence: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({ enforce_sanitization: true }),
    if: :gitpod_enabled

  validates :mailgun_signing_key,
    presence: true,
    length: { maximum: 255 },
    if: :mailgun_events_enabled

  validates :snowplow_collector_hostname,
    presence: true,
    hostname: true,
    if: :snowplow_enabled

  validates :snowplow_database_collector_hostname,
    allow_blank: true,
    hostname: true,
    length: { maximum: 255 }

  validates :max_pages_size,
    presence: true,
    numericality: {
      only_integer: true, greater_than_or_equal_to: 0,
      less_than: ::Gitlab::Pages::MAX_SIZE / 1.megabyte
    }

  validates :default_artifacts_expire_in, presence: true, duration: true

  validates :container_expiration_policies_enable_historic_entries,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validate :check_repository_storages_weighted

  validates :auto_devops_domain,
    allow_blank: true,
    hostname: { allow_numeric_hostname: true, require_valid_tld: true },
    if: :auto_devops_enabled?

  validates :enabled_git_access_protocol,
    inclusion: { in: %w[ssh http], allow_blank: true }

  validates :domain_denylist,
    presence: { message: 'Domain denylist cannot be empty if denylist is enabled.' },
    if: :domain_denylist_enabled?

  validates :polling_interval_multiplier,
    presence: true,
    numericality: { greater_than_or_equal_to: 0 }

  validates :gitaly_timeout_default,
    presence: true,
    if: :gitaly_timeout_default_changed?,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: Settings.gitlab.max_request_duration_seconds
    }

  validates :gitaly_timeout_medium,
    presence: true,
    if: :gitaly_timeout_medium_changed?,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :gitaly_timeout_medium,
    numericality: { less_than_or_equal_to: :gitaly_timeout_default },
    if: :gitaly_timeout_default
  validates :gitaly_timeout_medium,
    numericality: { greater_than_or_equal_to: :gitaly_timeout_fast },
    if: :gitaly_timeout_fast

  validates :gitaly_timeout_fast,
    presence: true,
    if: :gitaly_timeout_fast_changed?,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :gitaly_timeout_fast,
    numericality: { less_than_or_equal_to: :gitaly_timeout_default },
    if: :gitaly_timeout_default

  validates :diff_max_patch_bytes,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES,
      less_than_or_equal_to: Gitlab::Git::Diff::MAX_PATCH_BYTES_UPPER_BOUND
    }

  validates :diff_max_files,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: Commit::DEFAULT_MAX_DIFF_FILES_SETTING,
      less_than_or_equal_to: Commit::MAX_DIFF_FILES_SETTING_UPPER_BOUND
    }

  validates :diff_max_lines,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: Commit::DEFAULT_MAX_DIFF_LINES_SETTING,
      less_than_or_equal_to: Commit::MAX_DIFF_LINES_SETTING_UPPER_BOUND
    }

  validates :user_default_internal_regex, js_regex: true, allow_nil: true
  validates :default_preferred_language, presence: true, inclusion: { in: Gitlab::I18n.available_locales }

  validates :personal_access_token_prefix,
    format: {
      with: %r{\A[a-zA-Z0-9_+=/@:.-]+\z},
      message: N_("can contain only letters of the Base64 alphabet (RFC4648) with the addition of '@', ':' and '.'")
    },
    length: { maximum: 20, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true

  validates :commit_email_hostname, format: { with: /\A[^@]+\z/ }

  validates :archive_builds_in_seconds,
    allow_nil: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1.day.seconds,
      message: N_('must be at least 1 day')
    }

  validates :local_markdown_version,
    allow_nil: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 65536 }

  validates :asset_proxy_url,
    presence: true,
    allow_blank: false,
    url: true,
    if: :asset_proxy_enabled?

  validates :asset_proxy_secret_key,
    presence: true,
    allow_blank: false,
    if: :asset_proxy_enabled?

  validates :static_objects_external_storage_url,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS, allow_blank: true

  validates :static_objects_external_storage_auth_token,
    presence: true,
    if: :static_objects_external_storage_url?

  validates :protected_paths,
    length: { maximum: 100, message: N_('is too long (maximum is 100 entries)') },
    allow_nil: false

  validates :protected_paths_for_get_request,
    length: { maximum: 100, message: N_('is too long (maximum is 100 entries)') },
    allow_nil: false

  validates :push_event_activities_limit,
    :push_event_hooks_limit,
    numericality: { greater_than_or_equal_to: 0 }

  validates :wiki_page_max_content_bytes, numericality: { only_integer: true, greater_than_or_equal_to: 1.kilobyte }
  validates :wiki_asciidoc_allow_uri_includes, inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :email_restrictions, untrusted_regexp: true

  validates :hashed_storage_enabled,
    inclusion: { in: [true], message: N_("Hashed storage can't be disabled anymore for new projects") }

  validates :container_registry_expiration_policies_caching,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :invisible_captcha_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :invitation_flow_enforcement,
    :can_create_group,
    :can_create_organization,
    :allow_project_creation_for_guest_and_below,
    :user_defaults_to_private_profile,
    :enable_member_promotion_management,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :deactivate_dormant_users_period,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 90,
                    message: N_("'%{value}' days of inactivity must be greater than or equal to 90") },
    if: :deactivate_dormant_users?

  validates :allow_possible_spam,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :deny_all_requests_except_allowed,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :silent_mode_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :remember_me_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  Gitlab::SSHPublicKey.supported_types.each do |type|
    validates :"#{type}_key_restriction", presence: true, key_restriction: { type: type }
  end

  validates :allowed_key_types, presence: true

  validates_each :restricted_visibility_levels do |record, attr, value|
    value&.each do |level|
      unless Gitlab::VisibilityLevel.options.value?(level)
        record.errors.add(attr, format(_("'%{level}' is not a valid visibility level"), level: level))
      end
    end
  end

  validates :default_project_visibility, :default_group_visibility,
    exclusion: { in: :restricted_visibility_levels, message: "cannot be set to a restricted visibility level" },
    if: :should_prevent_visibility_restriction?

  validates_each :import_sources, on: :update do |record, attr, value|
    value&.each do |source|
      unless Gitlab::ImportSources.options.value?(source)
        record.errors.add(attr, format(_("'%{source}' is not a import source"), source: source))
      end
    end
  end

  validate :check_valid_runner_registrars

  validate :terms_exist, if: :enforce_terms?

  validates :external_authorization_service_default_label,
    presence: true,
    if: :external_authorization_service_enabled

  validates :external_authorization_service_url,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS, allow_blank: true,
    if: :external_authorization_service_enabled

  validates :external_authorization_service_timeout,
    numericality: { greater_than: 0, less_than_or_equal_to: 10 },
    if: :external_authorization_service_enabled

  validates :spam_check_endpoint_url,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({ schemes: %w[tls grpc] }), allow_blank: true

  validates :spam_check_endpoint_url,
    presence: true,
    if: :spam_check_endpoint_enabled

  validates :external_auth_client_key,
    presence: true,
    if: ->(setting) { setting.external_auth_client_cert.present? }

  validates :lets_encrypt_notification_email,
    devise_email: true,
    format: { without: /@example\.(com|org|net)\z/,
              message: N_("Let's Encrypt does not accept emails on example.com") },
    allow_blank: true

  validates :lets_encrypt_notification_email,
    presence: true,
    if: :lets_encrypt_terms_of_service_accepted?

  validates :eks_integration_enabled,
    inclusion: { in: [true, false] }

  validates :eks_account_id,
    format: { with: Gitlab::Regex.aws_account_id_regex, message: Gitlab::Regex.aws_account_id_message },
    if: :eks_integration_enabled?

  validates :eks_access_key_id,
    length: { in: 16..128 },
    if: ->(setting) { setting.eks_integration_enabled? && setting.eks_access_key_id.present? }

  validates :eks_secret_access_key,
    presence: true,
    if: ->(setting) { setting.eks_integration_enabled? && setting.eks_access_key_id.present? }

  validates_with X509CertificateCredentialsValidator,
    certificate: :external_auth_client_cert,
    pkey: :external_auth_client_key,
    pass: :external_auth_client_key_pass,
    if: ->(setting) { setting.external_auth_client_cert.present? }

  validates :default_ci_config_path,
    format: { without: %r{(\.{2}|\A/)}, message: N_('cannot include leading slash or directory traversal.') },
    length: { maximum: 255 },
    allow_blank: true

  validates :ci_jwt_signing_key,
    rsa_key: true, allow_nil: true

  validates :ci_job_token_signing_key,
    rsa_key: true, allow_nil: true

  validates :customers_dot_jwt_signing_key,
    rsa_key: true, allow_nil: true

  validates :rate_limiting_response_text,
    length: { maximum: 255, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true

  validates :jira_connect_application_key,
    length: { maximum: 255, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true

  validates :jira_connect_proxy_url,
    length: { maximum: 255, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true,
    public_url: ADDRESSABLE_URL_VALIDATION_OPTIONS

  jsonb_accessor :integrations,
    jira_connect_additional_audience_url: :string

  validates :jira_connect_additional_audience_url,
    length: { maximum: 255, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true,
    public_url: ADDRESSABLE_URL_VALIDATION_OPTIONS

  validates :integrations, json_schema: { filename: "application_setting_integrations" }

  with_options(presence: true, if: :slack_app_enabled?) do
    validates :slack_app_id
    validates :slack_app_secret
    validates :slack_app_signing_secret
    validates :slack_app_verification_token
  end

  with_options(numericality: { only_integer: true, greater_than: 0 }) do
    validates :ai_action_api_rate_limit,
      :bulk_import_concurrent_pipeline_batch_limit,
      :code_suggestions_api_rate_limit,
      :concurrent_bitbucket_import_jobs_limit,
      :concurrent_bitbucket_server_import_jobs_limit,
      :concurrent_github_import_jobs_limit,
      :concurrent_relation_batch_export_limit,
      :container_registry_token_expire_delay,
      :housekeeping_optimize_repository_period,
      :inactive_projects_delete_after_months,
      :max_artifacts_content_include_size,
      :max_artifacts_size,
      :max_attachment_size,
      :max_yaml_depth,
      :max_yaml_size_bytes,
      :namespace_aggregation_schedule_lease_duration_in_seconds,
      :project_jobs_api_rate_limit,
      :session_expire_delay,
      :snippet_size_limit,
      :throttle_authenticated_api_period_in_seconds,
      :throttle_authenticated_api_requests_per_period,
      :throttle_authenticated_deprecated_api_period_in_seconds,
      :throttle_authenticated_deprecated_api_requests_per_period,
      :throttle_authenticated_files_api_period_in_seconds,
      :throttle_authenticated_files_api_requests_per_period,
      :throttle_authenticated_git_lfs_period_in_seconds,
      :throttle_authenticated_git_lfs_requests_per_period,
      :throttle_authenticated_packages_api_period_in_seconds,
      :throttle_authenticated_packages_api_requests_per_period,
      :throttle_authenticated_web_period_in_seconds,
      :throttle_authenticated_web_requests_per_period,
      :throttle_protected_paths_period_in_seconds,
      :throttle_protected_paths_requests_per_period,
      :throttle_unauthenticated_api_period_in_seconds,
      :throttle_unauthenticated_api_requests_per_period,
      :throttle_unauthenticated_deprecated_api_period_in_seconds,
      :throttle_unauthenticated_deprecated_api_requests_per_period,
      :throttle_unauthenticated_files_api_period_in_seconds,
      :throttle_unauthenticated_files_api_requests_per_period,
      :throttle_unauthenticated_git_http_period_in_seconds,
      :throttle_unauthenticated_git_http_requests_per_period,
      :throttle_unauthenticated_packages_api_period_in_seconds,
      :throttle_unauthenticated_packages_api_requests_per_period,
      :throttle_unauthenticated_period_in_seconds,
      :throttle_unauthenticated_requests_per_period
  end

  with_options(numericality: { only_integer: true, greater_than_or_equal_to: 0 }) do
    validates :bulk_import_max_download_file_size,
      :ci_max_includes,
      :ci_max_total_yaml_size_bytes,
      :container_registry_cleanup_tags_service_max_list_size,
      :container_registry_data_repair_detail_worker_max_concurrency,
      :container_registry_delete_tags_service_timeout,
      :container_registry_expiration_policies_worker_capacity,
      :decompress_archive_file_timeout,
      :dependency_proxy_ttl_group_policy_worker_capacity,
      :downstream_pipeline_trigger_limit_per_project_user_sha,
      :gitlab_shell_operation_limit,
      :group_api_limit,
      :group_invited_groups_api_limit,
      :group_projects_api_limit,
      :group_shared_groups_api_limit,
      :groups_api_limit,
      :inactive_projects_min_size_mb,
      :issues_create_limit,
      :jobs_per_stage_page_size,
      :max_decompressed_archive_size,
      :max_export_size,
      :max_import_remote_file_size,
      :max_import_size,
      :max_pages_custom_domains_per_project,
      :max_terraform_state_size_bytes,
      :members_delete_limit,
      :notes_create_limit,
      :create_organization_api_limit,
      :package_registry_cleanup_policies_worker_capacity,
      :packages_cleanup_package_file_worker_capacity,
      :pages_extra_deployments_default_expiry_seconds,
      :pipeline_limit_per_project_user_sha,
      :project_api_limit,
      :project_invited_groups_api_limit,
      :projects_api_limit,
      :projects_api_rate_limit_unauthenticated,
      :raw_blob_request_limit,
      :search_rate_limit,
      :search_rate_limit_unauthenticated,
      :sidekiq_job_limiter_compression_threshold_bytes,
      :sidekiq_job_limiter_limit_bytes,
      :terminal_max_session_time,
      :user_contributed_projects_api_limit,
      :user_projects_api_limit,
      :user_starred_projects_api_limit,
      :users_get_by_id_limit
  end

  attribute :resource_usage_limits, ::Gitlab::Database::Type::IndifferentJsonb.new, default: -> { {} }
  validates :resource_usage_limits, json_schema: { filename: 'resource_usage_limits' }

  jsonb_accessor :rate_limits,
    concurrent_bitbucket_import_jobs_limit: [:integer, { default: 100 }],
    concurrent_bitbucket_server_import_jobs_limit: [:integer, { default: 100 }],
    concurrent_github_import_jobs_limit: [:integer, { default: 1000 }],
    concurrent_relation_batch_export_limit: [:integer, { default: 8 }],
    downstream_pipeline_trigger_limit_per_project_user_sha: [:integer, { default: 0 }],
    group_api_limit: [:integer, { default: 400 }],
    group_invited_groups_api_limit: [:integer, { default: 60 }],
    group_projects_api_limit: [:integer, { default: 600 }],
    group_shared_groups_api_limit: [:integer, { default: 60 }],
    groups_api_limit: [:integer, { default: 200 }],
    members_delete_limit: [:integer, { default: 60 }],
    create_organization_api_limit: [:integer, { default: 10 }],
    project_api_limit: [:integer, { default: 400 }],
    project_invited_groups_api_limit: [:integer, { default: 60 }],
    projects_api_limit: [:integer, { default: 2000 }],
    user_contributed_projects_api_limit: [:integer, { default: 100 }],
    user_projects_api_limit: [:integer, { default: 300 }],
    user_starred_projects_api_limit: [:integer, { default: 100 }]

  jsonb_accessor :service_ping_settings,
    gitlab_environment_toolkit_instance: [:boolean, { default: false }]

  jsonb_accessor :rate_limits_unauthenticated_git_http,
    throttle_unauthenticated_git_http_enabled: [:boolean, { default: false }],
    throttle_unauthenticated_git_http_requests_per_period: [:integer, { default: 3600 }],
    throttle_unauthenticated_git_http_period_in_seconds: [:integer, { default: 3600 }]

  jsonb_accessor :importers,
    silent_admin_exports_enabled: [:boolean, { default: false }],
    allow_contribution_mapping_to_admins: [:boolean, { default: false }]

  jsonb_accessor :sign_in_restrictions,
    disable_password_authentication_for_users_with_sso_identities: [:boolean, { default: false }],
    root_moved_permanently_redirection: [:boolean, { default: false }]

  validates :sign_in_restrictions, json_schema: { filename: 'application_setting_sign_in_restrictions' }

  jsonb_accessor :search,
    global_search_issues_enabled: [:boolean, { default: true }],
    global_search_merge_requests_enabled: [:boolean, { default: true }],
    global_search_snippet_titles_enabled: [:boolean, { default: true }],
    global_search_users_enabled: [:boolean, { default: true }]

  validates :search, json_schema: { filename: 'application_setting_search' }

  jsonb_accessor :transactional_emails,
    resource_access_token_notify_inherited: [:boolean, { default: false }],
    lock_resource_access_token_notify_inherited: [:boolean, { default: false }]

  validates :transactional_emails, json_schema: { filename: "application_setting_transactional_emails" }

  validates :rate_limits, json_schema: { filename: "application_setting_rate_limits" }

  validates :importers, json_schema: { filename: "application_setting_importers" }

  jsonb_accessor :package_registry, nuget_skip_metadata_url_validation: [:boolean, { default: false }]

  jsonb_accessor :oauth_provider, ropc_without_client_credentials: [:boolean, { default: true }]

  validates :package_registry, json_schema: { filename: 'application_setting_package_registry' }

  validates :search_rate_limit_allowlist,
    length: { maximum: 100, message: N_('is too long (maximum is 100 entries)') },
    allow_nil: false

  validates :notes_create_limit_allowlist,
    length: { maximum: 100, message: N_('is too long (maximum is 100 entries)') },
    allow_nil: false

  validates :admin_mode,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :external_pipeline_validation_service_url,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS, allow_blank: true

  validates :whats_new_variant,
    inclusion: { in: ApplicationSetting.whats_new_variants.keys }

  validates :floc_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  enum :sidekiq_job_limiter_mode, {
    Gitlab::SidekiqMiddleware::SizeLimiter::Validator::TRACK_MODE => 0,
    Gitlab::SidekiqMiddleware::SizeLimiter::Validator::COMPRESS_MODE => 1 # The default
  }

  validates :sidekiq_job_limiter_mode,
    inclusion: { in: sidekiq_job_limiter_modes }

  validates :sentry_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }
  validates :sentry_dsn,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS, presence: true, length: { maximum: 255 },
    if: :sentry_enabled?
  validates :sentry_clientside_dsn,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS, allow_blank: true, length: { maximum: 255 },
    if: :sentry_enabled?
  validates :sentry_environment,
    presence: true, length: { maximum: 255 },
    if: :sentry_enabled?

  validates :error_tracking_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }
  validates :error_tracking_api_url,
    presence: true,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS,
    length: { maximum: 255 },
    if: :error_tracking_enabled?

  validates :users_get_by_id_limit_allowlist,
    length: { maximum: 100, message: N_('is too long (maximum is 100 entries)') },
    allow_nil: false

  validates :update_runner_versions_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }
  validates :public_runner_releases_url,
    addressable_url: ADDRESSABLE_URL_VALIDATION_OPTIONS,
    presence: true,
    if: :update_runner_versions_enabled?

  validates :inactive_projects_send_warning_email_after_months,
    numericality: { only_integer: true, greater_than: 0, less_than: :inactive_projects_delete_after_months }

  validates :prometheus_alert_db_indicators_settings,
    json_schema: { filename: 'application_setting_prometheus_alert_db_indicators_settings' }, allow_nil: true

  validates :sentry_clientside_traces_sample_rate,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1,
                    message: N_('must be a value between 0 and 1') }

  validates :package_registry_allow_anyone_to_pull_option,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :security_txt_content,
    length: { maximum: 2_048, message: N_('is too long (maximum is %{count} characters)') },
    allow_blank: true

  validates :asciidoc_max_includes,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 64 }

  jsonb_accessor :pages, pages_extra_deployments_default_expiry_seconds: [:integer, { default: 86400 }]
  validates :pages, json_schema: { filename: "application_setting_pages" }

  validates :enforce_ci_inbound_job_token_scope_enabled,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  attr_encrypted :asset_proxy_secret_key,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_truncated,
    algorithm: 'aes-256-cbc',
    insecure_mode: true

  private_class_method def self.encryption_options_base_32_aes_256_gcm
    {
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: true
    }
  end

  attr_encrypted :external_auth_client_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :external_auth_client_key_pass, encryption_options_base_32_aes_256_gcm
  attr_encrypted :lets_encrypt_private_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :eks_secret_access_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :akismet_api_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :spam_check_api_key, encryption_options_base_32_aes_256_gcm.merge(encode: false)
  attr_encrypted :elasticsearch_aws_secret_access_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :elasticsearch_password, encryption_options_base_32_aes_256_gcm.merge(encode: false)
  attr_encrypted :recaptcha_private_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :recaptcha_site_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :slack_app_secret, encryption_options_base_32_aes_256_gcm
  attr_encrypted :slack_app_signing_secret,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :slack_app_verification_token, encryption_options_base_32_aes_256_gcm
  attr_encrypted :ci_jwt_signing_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :ci_job_token_signing_key,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :customers_dot_jwt_signing_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :secret_detection_token_revocation_token, encryption_options_base_32_aes_256_gcm
  attr_encrypted :cloud_license_auth_token, encryption_options_base_32_aes_256_gcm
  attr_encrypted :external_pipeline_validation_service_token, encryption_options_base_32_aes_256_gcm
  attr_encrypted :mailgun_signing_key, encryption_options_base_32_aes_256_gcm.merge(encode: false)
  attr_encrypted :database_grafana_api_key,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :arkose_labs_client_xid, encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :arkose_labs_client_secret,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :arkose_labs_public_api_key,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :arkose_labs_private_api_key,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :arkose_labs_data_exchange_key,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :cube_api_key, encryption_options_base_32_aes_256_gcm
  attr_encrypted :telesign_customer_xid, encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :telesign_api_key, encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :product_analytics_configurator_connection_string,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)
  attr_encrypted :secret_detection_service_auth_token,
    encryption_options_base_32_aes_256_gcm.merge(encode: false, encode_iv: false)

  # Restricting the validation to `on: :update` only to avoid cyclical dependencies with
  # License <--> ApplicationSetting. This method calls a license check when we create
  # ApplicationSetting from defaults which in turn depends on ApplicationSetting record.
  # The correct default is defined in the `defaults` method so we don't need to validate
  # it here.
  validates :disable_feed_token,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }, on: :update

  validates :disable_admin_oauth_scopes,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :bulk_import_enabled,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :allow_runner_registration_token,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :default_syntax_highlighting_theme,
    allow_nil: false,
    numericality: { only_integer: true, greater_than: 0 },
    inclusion: { in: Gitlab::ColorSchemes.valid_ids, message: N_('must be a valid syntax highlighting theme ID') }

  validates :gitlab_dedicated_instance,
    allow_nil: false,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :service_ping_settings, json_schema: { filename: 'application_setting_service_ping_settings' }

  validates :math_rendering_limits_enabled,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :require_admin_two_factor_authentication,
    inclusion: { in: [true, false], message: N_('must be a boolean value') }

  validates :secret_detection_service_url,
    allow_blank: true,
    length: { maximum: 255 }

  before_validation :ensure_uuid!
  before_validation :coerce_repository_storages_weighted, if: :repository_storages_weighted_changed?
  before_validation :normalize_default_branch_name

  before_save :ensure_runners_registration_token
  before_save :ensure_health_check_access_token
  before_save :ensure_error_tracking_access_token

  after_commit do
    reset_memoized_terms
  end
  after_commit :expire_performance_bar_allowed_user_ids_cache, if: -> {
    previous_changes.key?('performance_bar_allowed_group_id')
  }
  after_commit :reset_deletion_warning_redis_key, if: :should_reset_inactive_project_deletion_warning?

  def validate_grafana_url
    validate_url(parsed_grafana_url, :grafana_url, GRAFANA_URL_ERROR_MESSAGE)
  end

  def grafana_url_absolute?
    parsed_grafana_url&.absolute?
  end

  def validate_kroki_url
    validate_url(parsed_kroki_url, :kroki_url, KROKI_URL_ERROR_MESSAGE)
  end

  def kroki_url_absolute?
    parsed_kroki_url&.absolute?
  end

  def sourcegraph_url_is_com?
    !!(sourcegraph_url =~ %r{\Ahttps://(www\.)?sourcegraph\.com})
  end

  def normalize_default_branch_name
    self.default_branch_name = default_branch_name.presence
  end

  def default_branch_protected?
    Gitlab::Access::DefaultBranchProtection.new(default_branch_protection_defaults).any?
  end

  def instance_review_permitted?
    users_count = Rails.cache.fetch('limited_users_count', expires_in: 1.day) do
      ::User.limit(INSTANCE_REVIEW_MIN_USERS + 1).count(:all)
    end

    users_count >= INSTANCE_REVIEW_MIN_USERS
  end

  Recursion = Class.new(RuntimeError)

  def self.create_from_defaults
    # this is possible if calls to create the record depend on application
    # settings themselves. This was seen in the case of a feature flag called by
    # `transaction` that ended up requiring application settings to determine metrics behavior.
    # If something like that happens, we break the loop here, and let the caller decide how to manage it.
    raise Recursion if Thread.current[:application_setting_create_from_defaults]

    Thread.current[:application_setting_create_from_defaults] = true

    check_schema!

    transaction(requires_new: true) do # rubocop:disable Performance/ActiveRecordSubtransactions
      super
    end
  rescue ActiveRecord::RecordNotUnique
    # We already have an ApplicationSetting record, so just return it.
    current_without_cache
  ensure
    Thread.current[:application_setting_create_from_defaults] = nil
  end

  def self.find_or_create_without_cache
    current_without_cache || create_from_defaults
  end

  # Due to the frequency with which settings are accessed, it is
  # likely that during a backup restore a running GitLab process
  # will insert a new `application_settings` row before the
  # constraints have been added to the table. This would add an
  # extra row with ID 1 and prevent the primary key constraint from
  # being added, which made ActiveRecord throw a
  # IrreversibleOrderError anytime the settings were accessed
  # (https://gitlab.com/gitlab-org/gitlab/-/issues/36405).  To
  # prevent this from happening, we do a sanity check that the
  # primary key constraint is present before inserting a new entry.
  def self.check_schema!
    return if connection.primary_key(table_name).present?

    raise "The `#{table_name}` table is missing a primary key constraint in the database schema"
  end

  # By default, the backend is Rails.cache, which uses
  # ActiveSupport::Cache::RedisStore. Since loading ApplicationSetting
  # can cause a significant amount of load on Redis, let's cache it in
  # memory.
  def self.cache_backend
    Gitlab::ProcessMemoryCache.cache_backend
  end

  def self.human_attribute_name(attribute, *options)
    HUMANIZED_ATTRIBUTES[attribute.to_sym] || super
  end

  def recaptcha_or_login_protection_enabled
    recaptcha_enabled || login_recaptcha_protection_enabled
  end

  kroki_formats_attributes.each_key do |key|
    define_method :"kroki_formats_#{key}=" do |value|
      super(::Gitlab::Utils.to_boolean(value))
    end
  end

  def kroki_format_supported?(diagram_type)
    case diagram_type
    when 'excalidraw'
      return kroki_formats_excalidraw
    when 'bpmn'
      return kroki_formats_bpmn
    end

    return kroki_formats_blockdiag if ::Gitlab::Kroki::BLOCKDIAG_FORMATS.include?(diagram_type)

    ::AsciidoctorExtensions::Kroki::SUPPORTED_DIAGRAM_NAMES.include?(diagram_type)
  end

  def personal_access_tokens_disabled?
    false
  end

  def max_login_attempts_column_exists?
    self.class.database.cached_column_exists?(:max_login_attempts)
  end

  def failed_login_attempts_unlock_period_in_minutes_column_exists?
    self.class.database.cached_column_exists?(:failed_login_attempts_unlock_period_in_minutes)
  end

  private

  def parsed_grafana_url
    @parsed_grafana_url ||= Gitlab::Utils.parse_url(grafana_url)
  end

  def parsed_kroki_url
    @parsed_kroki_url ||= Gitlab::HTTP_V2::UrlBlocker.validate!(
      kroki_url, schemes: %w[http https],
      enforce_sanitization: true,
      deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
      outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist)[0]
  rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
    errors.add(
      :kroki_url,
      "is not valid. #{e}"
    )
  end

  def validate_url(parsed_url, name, error_message)
    return if parsed_url

    errors.add(
      name,
      "must be a valid relative or absolute URL. #{error_message}"
    )
  end

  def reset_deletion_warning_redis_key
    Gitlab::InactiveProjectsDeletionWarningTracker.reset_all
  end

  def should_prevent_visibility_restriction?
    default_project_visibility_changed? ||
      default_group_visibility_changed? ||
      restricted_visibility_levels_changed?
  end

  def should_reset_inactive_project_deletion_warning?
    saved_change_to_inactive_projects_delete_after_months? || saved_change_to_delete_inactive_projects?(from: true,
      to: false)
  end
end

ApplicationSetting.prepend_mod_with('ApplicationSetting')
