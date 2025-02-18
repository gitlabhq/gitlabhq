#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'yaml'

require_relative '../../lib/gitlab'

class ApplicationSettingsAnalysis
  CODEBASE_FIELDS = %i[
    column
    db_type
    api_type
    encrypted
    not_null
    default
    gitlab_com_different_than_default
    description
    jihu
  ].freeze
  ApplicationSettingPrototype = Struct.new(
    *CODEBASE_FIELDS,
    :attr,
    :clusterwide,
    keyword_init: true)

  class ApplicationSetting < ApplicationSettingPrototype
    # Computed from Teleport Rails console with:
    # ```shell
    # $ as = Gitlab::CurrentSettings.current_application_settings
    # $ as_defaults = ApplicationSetting.defaults
    # $ new_as = ApplicationSetting.new
    # $ diff_than_def = as.attributes.to_h.select { |k, v| (as_defaults[k] || new_as[k]) != v }; nil
    # $ diff_than_def_valid_columns = diff_than_def.keys.reject { |k| k.match?(%r{^(encrypted_\w+_iv|\w+_html)$}) }
    # $ diff_than_def_valid_columns.sort.each { |d| puts d }; nil
    # ```
    #
    # rubocop:disable Naming/InclusiveLanguage -- This is the actual column name
    GITLAB_COM_DIFFERENT_THAN_DEFAULT = %w[
      abuse_notification_email
      after_sign_out_path
      after_sign_up_text
      allow_top_level_group_owners_to_create_service_accounts
      arkose_labs_namespace
      asset_proxy_enabled
      asset_proxy_url
      asset_proxy_whitelist
      authorized_keys_enabled
      auto_devops_domain
      auto_devops_enabled
      automatic_purchased_storage_allocation
      bulk_import_enabled
      check_namespace_plan
      clickhouse
      cluster_agents
      code_creation
      commit_email_hostname
      concurrent_relation_batch_export_limit
      container_expiration_policies_enable_historic_entries
      container_registry_data_repair_detail_worker_max_concurrency
      container_registry_db_enabled
      container_registry_expiration_policies_worker_capacity
      container_registry_features
      container_registry_token_expire_delay
      container_registry_vendor
      container_registry_version
      created_at
      cube_api_base_url
      custom_http_clone_url_root
      dashboard_limit
      dashboard_limit_enabled
      database_grafana_api_url
      database_grafana_tag
      database_max_running_batched_background_migrations
      deactivation_email_additional_text
      default_artifacts_expire_in
      default_branch_name
      default_branch_protection_defaults
      default_ci_config_path
      default_group_visibility
      default_projects_limit
      delete_unconfirmed_users
      diff_max_files
      diff_max_lines
      domain_denylist
      domain_denylist_enabled
      downstream_pipeline_trigger_limit_per_project_user_sha
      duo_workflow
      duo_workflow_oauth_application_id
      eks_access_key_id
      eks_account_id
      eks_integration_enabled
      elasticsearch
      elasticsearch_aws_access_key
      elasticsearch_client_request_timeout
      elasticsearch_indexed_field_length_limit
      elasticsearch_indexing
      elasticsearch_limit_indexing
      elasticsearch_max_code_indexing_concurrency
      elasticsearch_requeue_workers
      elasticsearch_retry_on_failure
      elasticsearch_search
      elasticsearch_url
      elasticsearch_username
      elasticsearch_worker_number_of_shards
      email_additional_text
      email_confirmation_setting
      email_restrictions
      email_restrictions_enabled
      enabled_git_access_protocol
      encrypted_akismet_api_key
      encrypted_arkose_labs_client_secret
      encrypted_arkose_labs_client_xid
      encrypted_arkose_labs_data_exchange_key
      encrypted_arkose_labs_private_api_key
      encrypted_arkose_labs_public_api_key
      encrypted_asset_proxy_secret_key
      encrypted_ci_job_token_signing_key
      encrypted_ci_jwt_signing_key
      encrypted_cube_api_key
      encrypted_customers_dot_jwt_signing_key
      encrypted_database_grafana_api_key
      encrypted_eks_secret_access_key
      encrypted_elasticsearch_aws_secret_access_key
      encrypted_elasticsearch_password
      encrypted_external_pipeline_validation_service_token
      encrypted_lets_encrypt_private_key
      encrypted_mailgun_signing_key
      encrypted_product_analytics_configurator_connection_string
      encrypted_recaptcha_private_key
      encrypted_recaptcha_site_key
      encrypted_secret_detection_service_auth_token
      encrypted_secret_detection_token_revocation_token
      encrypted_slack_app_secret
      encrypted_slack_app_signing_secret
      encrypted_slack_app_verification_token
      encrypted_spam_check_api_key
      encrypted_telesign_api_key
      encrypted_telesign_customer_xid
      enforce_terms
      error_tracking_access_token_encrypted
      error_tracking_api_url
      error_tracking_enabled
      external_authorization_service_default_label
      external_authorization_service_url
      external_pipeline_validation_service_timeout
      external_pipeline_validation_service_url
      geo_status_timeout
      gitpod_enabled
      globally_allowed_ips
      gravatar_enabled
      health_check_access_token
      help_page_documentation_base_url
      help_page_support_url
      help_page_text
      home_page_url
      identity_verification_settings
      import_sources
      importers
      integrations
      invisible_captcha_enabled
      issues_create_limit
      jira_connect_application_key
      jira_connect_proxy_url
      jira_connect_public_key_storage_enabled
      lets_encrypt_notification_email
      lets_encrypt_terms_of_service_accepted
      local_markdown_version
      mailgun_events_enabled
      maven_package_requests_forwarding
      max_artifacts_size
      max_export_size
      max_import_size
      max_pages_custom_domains_per_project
      max_pages_size
      metrics_enabled
      metrics_method_call_threshold
      metrics_packet_size
      metrics_port
      mirror_capacity_threshold
      mirror_max_capacity
      mirror_max_delay
      namespace_storage_forks_cost_factor
      notes_create_limit
      notes_create_limit_allowlist
      oauth_provider
      observability_settings
      outbound_local_requests_whitelist
      package_registry
      pages
      password_authentication_enabled_for_web
      performance_bar_allowed_group_id
      pipeline_limit_per_project_user_sha
      plantuml_enabled
      plantuml_url
      secret_push_protection_available
      product_analytics_data_collector_host
      product_analytics_enabled
      productivity_analytics_start_date
      prometheus_alert_db_indicators_settings
      push_rule_id
      rate_limiting_response_text
      rate_limits
      rate_limits_unauthenticated_git_http
      recaptcha_enabled
      receive_max_input_size
      repository_size_limit
      repository_storages
      repository_storages_weighted
      require_admin_approval_after_user_signup
      require_admin_two_factor_authentication
      restricted_visibility_levels
      runners_registration_token_encrypted
      search
      search_rate_limit
      search_rate_limit_allowlist
      secret_detection_revocation_token_types_url
      secret_detection_service_url
      secret_detection_token_revocation_enabled
      secret_detection_token_revocation_url
      security_policies
      security_policy_global_group_approvers_enabled
      security_txt_content
      sentry_clientside_dsn
      sentry_clientside_traces_sample_rate
      sentry_dsn
      sentry_enabled
      sentry_environment
      service_ping_settings
      shared_runners_minutes
      shared_runners_text
      sidekiq_job_limiter_limit_bytes
      signup_enabled
      silent_admin_exports_enabled
      slack_app_enabled
      slack_app_id
      snowplow_app_id
      snowplow_collector_hostname
      snowplow_cookie_domain
      snowplow_enabled
      sourcegraph_enabled
      sourcegraph_url
      spam_check_endpoint_enabled
      spam_check_endpoint_url
      static_objects_external_storage_auth_token_encrypted
      static_objects_external_storage_url
      throttle_authenticated_api_enabled
      throttle_authenticated_api_period_in_seconds
      throttle_authenticated_api_requests_per_period
      throttle_authenticated_deprecated_api_period_in_seconds
      throttle_authenticated_web_enabled
      throttle_authenticated_web_period_in_seconds
      throttle_authenticated_web_requests_per_period
      throttle_incident_management_notification_enabled
      throttle_protected_paths_enabled
      throttle_unauthenticated_api_enabled
      throttle_unauthenticated_api_period_in_seconds
      throttle_unauthenticated_api_requests_per_period
      throttle_unauthenticated_deprecated_api_requests_per_period
      throttle_unauthenticated_enabled
      throttle_unauthenticated_git_http_enabled
      throttle_unauthenticated_git_http_period_in_seconds
      throttle_unauthenticated_git_http_requests_per_period
      throttle_unauthenticated_period_in_seconds
      throttle_unauthenticated_requests_per_period
      time_tracking_limit_to_hours
      transactional_emails
      two_factor_grace_period
      unconfirmed_users_delete_after_days
      unique_ips_limit_per_user
      unique_ips_limit_time_window
      updated_at
      usage_stats_set_by_user_id
      use_clickhouse_for_analytics
      user_default_internal_regex
      users_get_by_id_limit_allowlist
      uuid
      vertex_ai_project
      web_ide_oauth_application_id
      zoekt_cpu_to_tasks_ratio
      zoekt_indexing_enabled
      zoekt_search_enabled
      zoekt_settings
    ].freeze
    # rubocop:enable Naming/InclusiveLanguage

    AS_MODEL = File.read('app/models/application_setting.rb') +
      (File.read('ee/app/models/ee/application_setting.rb') if Gitlab.ee?).to_s

    def initialize(hash)
      super

      self[:encrypted] = encrypted_column?
      self[:clusterwide] = true
      self[:attr] = infer_attribute_name
      self[:gitlab_com_different_than_default] = GITLAB_COM_DIFFERENT_THAN_DEFAULT.include?(column)
      populate_fields_from_definition!
    end

    def populate_fields_from_definition!
      definition.each do |k, v|
        next if v.nil?
        next if CODEBASE_FIELDS.include?(k.to_sym)

        self[k] = v
      end
    end

    def definition_file_path
      File.expand_path("../../config/application_setting_columns/#{attr}.yml", __dir__)
    end

    def definition_file_exist?
      File.exist?(definition_file_path)
    end

    private

    def definition
      @definition ||= definition_file_exist? ? YAML.safe_load_file(definition_file_path) : {}
    end

    def encrypted_column?
      column.start_with?('encrypted_') || column.end_with?('_encrypted') || AS_MODEL.match?("encrypts :#{column}")
    end

    def infer_attribute_name
      column.delete_prefix('encrypted_').delete_suffix('_encrypted')
    end
  end

  ApplicationSettingApiDoc = Struct.new(:attr, :db_type, :api_type, :required, :description, keyword_init: true)

  ENUM_ATTRIBUTES = %w[
    default_group_visibility
    default_project_visibility
    default_snippet_visibility
    email_confirmation_setting
    performance_bar_allowed_group_id
    sidekiq_job_limiter_mode
    whats_new_variant
  ].freeze
  API_TYPE_STRING_OR_ARRAY_OF_STRING = ['string', 'array of strings', 'string or array of strings'].freeze
  API_TYPE_ARRAY_OF_INTEGER = ['array of integers'].freeze
  API_TYPE_INTEGER = ['integer'].freeze
  API_TYPE_FLOAT = ['float'].freeze
  DB_TYPE_TO_COMPATIBLE_API_TYPES = {
    'character' => API_TYPE_STRING_OR_ARRAY_OF_STRING,
    'text' => API_TYPE_STRING_OR_ARRAY_OF_STRING,
    'text[]' => API_TYPE_STRING_OR_ARRAY_OF_STRING,
    'bytea' => API_TYPE_STRING_OR_ARRAY_OF_STRING,
    'integer[]' => API_TYPE_ARRAY_OF_INTEGER,
    'smallint[]' => API_TYPE_ARRAY_OF_INTEGER,
    'jsonb' => ['hash', 'hash of strings to integers', 'object'],
    'smallint' => API_TYPE_INTEGER,
    'bigint' => API_TYPE_INTEGER,
    'double' => API_TYPE_FLOAT,
    'numeric' => API_TYPE_FLOAT
  }.freeze

  DB_STRUCTURE_FILE_PATH = File.expand_path('../../db/structure.sql', __dir__)
  CREATE_TABLE_REGEX = /CREATE TABLE application_settings \((?<columns>.+?)\);/m
  JIHU_COMMENT_REGEX = /COMMENT ON COLUMN application_settings.(?<column>\w+) IS 'JiHu-specific column';/
  IGNORED_COLUMNS_REGEX = %r{
    ^(
      encrypted_\w+_iv # ignore encryption-related extra columns
      |
      \w+_html # ignore Markdown-caching extra columns
    )$
  }x
  DEFAULT_REGEX = /DEFAULT (?<default>[^\s,]+)/

  DOC_API_SETTINGS_FILE_PATH = File.expand_path('../../doc/api/settings.md', __dir__)
  DOC_API_SETTINGS_TABLE_REGEX = Regexp.new(
    "## Available settings(?:.*?)(?:--\|\n)+?(?<rows>.+)" \
      "### Inactive project settings", Regexp::MULTILINE
  )

  DOC_PAGE_HEADERS = [
    "---",
    "stage: Tenant Scale",
    "group: Cells Infrastructure",
    "info: Analysis of Application Settings for Cells 1.0.",
    "---",
    "# Application Settings analysis\n",
    "## Statistics\n"
  ].freeze

  def self.definition_files
    @definition_files ||= Dir.glob(File.expand_path("../../config/application_setting_columns/*.yml", __dir__))
  end

  def initialize(stdout: $stdout)
    @stdout = stdout
  end

  def execute
    warn_about_virtual_attributes!
    write_attributes!
    write_documentation_page!
    clean_outdated_definition_files!
  end

  def attributes
    @attributes ||= begin
      structure_sql = File.read(DB_STRUCTURE_FILE_PATH)
      match = structure_sql.match(CREATE_TABLE_REGEX)
      jihu_columns = structure_sql.scan(JIHU_COMMENT_REGEX).flatten
      structure_columns = match[:columns].lines(chomp: true).map(&:strip).reject do |line|
        line.empty? || line.start_with?('CONSTRAINT')
      end.sort

      structure_columns.filter_map do |line|
        # Example lines:
        # throttle_authenticated_packages_api_requests_per_period integer DEFAULT 1000 NOT NULL
        # valid_runner_registrars character varying[] DEFAULT '{project,group}'::character varying[]
        column, db_type = line.chomp(',').split(' ').map(&:strip)
        next if column.match?(IGNORED_COLUMNS_REGEX)

        default_match = line.match(DEFAULT_REGEX)&.values_at(:default)&.first

        ApplicationSetting.new(column: column, db_type: db_type, not_null: line.include?('NOT NULL'),
          default: default_match, jihu: jihu_columns.include?(column)).tap do |as_attr|
          as_attr.api_type, as_attr.description = fetch_type_and_description_from_api_documentation(as_attr)
        end
      end
    end.sort_by(&:attr)
  end

  private

  attr_reader :stdout, :application_setting_attrs

  def documentation_api_settings
    @documentation_api_settings ||= begin
      settings_md = File.read(DOC_API_SETTINGS_FILE_PATH)
      match = settings_md.match(DOC_API_SETTINGS_TABLE_REGEX)
      doc_rows = match[:rows].lines(chomp: true).map(&:strip).filter_map do |line|
        line.delete_prefix("| ") if line.start_with?('| `')
      end.sort

      doc_rows.map do |line|
        attr, api_type, required, description = line.split('|').map(&:strip)
        attr.delete!('`')

        ApplicationSettingApiDoc.new(attr: attr, api_type: api_type, required: required, description: description)
      end
    end
  end

  def fetch_type_and_description_from_api_documentation(as_attr)
    existing_attribute_from_doc_api_settings = documentation_api_settings.find do |api|
      api.attr == as_attr.attr
    end
    return unless existing_attribute_from_doc_api_settings

    compatible_api_types = DB_TYPE_TO_COMPATIBLE_API_TYPES.fetch(as_attr.db_type, [as_attr.db_type])
    if ENUM_ATTRIBUTES.include?(as_attr.attr) && compatible_api_types.include?('integer')
      compatible_api_types = ['string']
    end

    unless compatible_api_types.include?(existing_attribute_from_doc_api_settings.api_type)
      raise "`#{as_attr.attr}`: Documented type `#{existing_attribute_from_doc_api_settings.api_type}` " \
        "isn't compatible with actual DB type `#{as_attr.db_type}`!"
    end

    [existing_attribute_from_doc_api_settings.api_type, existing_attribute_from_doc_api_settings.description]
  end

  def warn_about_virtual_attributes!
    db_structure_attrs = attributes.map(&:attr)
    virtual_api_settings = documentation_api_settings.reject { |api| db_structure_attrs.include?(api.attr) }
    virtual_api_settings.each do |virtual_api_setting|
      stdout.puts "API setting `#{virtual_api_setting.attr}` doesn't actually exist as a DB " \
        "column in `application_settings`!"
    end
  end

  def write_attributes!
    attributes.each do |final_attribute|
      File.write(
        final_attribute.definition_file_path,
        Hash[final_attribute.to_h.sort].transform_keys(&:to_s).to_yaml
      )
    end
  end

  def clean_outdated_definition_files!
    valid_attribute_names = attributes.map(&:attr)

    self.class.definition_files.each do |path|
      attribute_name = File.basename(path, '.yml')
      next if valid_attribute_names.include?(attribute_name)

      stdout.puts "Deleting #{path} since the #{attribute_name} attribute doesn't exist anymore."
      File.unlink(path)
    end
  end

  def write_documentation_page! # rubocop:disable Metrics/AbcSize: -- The method generates a doc page so it's a bit special
    doc_page = DOC_PAGE_HEADERS.dup

    doc_page << "- Number of attributes: #{attributes.count}"

    as_encrypted = attributes.count(&:encrypted)
    doc_page << "- Number of encrypted attributes: #{as_encrypted} " \
      "(#{(as_encrypted.to_f / attributes.count).round(2) * 100}%)"

    as_documented = attributes.count(&:description)
    doc_page << "- Number of attributes documented: #{as_documented} " \
      "(#{(as_documented.to_f / attributes.count).round(2) * 100}%)"

    as_on_gitlab_com_different_than_default = attributes.count(&:gitlab_com_different_than_default)
    doc_page << "- Number of attributes on GitLab.com different from the defaults: " \
      "#{as_on_gitlab_com_different_than_default} " \
      "(#{(as_on_gitlab_com_different_than_default.to_f / attributes.count).round(2) * 100}%)"

    as_with_clusterwide_set = attributes.count { |as| !as.clusterwide.nil? }
    doc_page << "- Number of attributes with `clusterwide` set: #{as_with_clusterwide_set} " \
      "(#{(as_with_clusterwide_set.to_f / attributes.count).round(2) * 100}%)"

    as_with_clusterwide_true = attributes.count(&:clusterwide)
    doc_page << "- Number of attributes with `clusterwide: true` set: #{as_with_clusterwide_true} " \
      "(#{(as_with_clusterwide_true.to_f / attributes.count).round(2) * 100}%)\n"

    doc_page << "## Individual columns\n"
    doc_page << "| Attribute name | Encrypted | DB Type | API Type | Not Null? | Default | " \
      "GitLab.com != default | Cluster-wide? | Documented? |"
    doc_page << "| -------------- | ------------- | --------- | --------- | ----------------- | " \
      "--------------------- | ------------- | ----------- |"

    attributes.each do |as|
      jihu = as.jihu ? ' [JIHU]' : ''
      doc_page << "| `#{as.attr}`#{jihu} | `#{as.encrypted}` | `#{as.db_type}` | `#{as.api_type}` | `#{as.not_null}` " \
        "| `#{as.default || (as.not_null ? '???' : 'null')}` | `#{as.gitlab_com_different_than_default}` " \
        "| `#{as.clusterwide.nil? ? '???' : as.clusterwide}`| `#{!!as.description}` |"
    end

    doc_page << '' # trailing line

    File.write(File.expand_path("../../doc/development/cells/application_settings_analysis.md", __dir__),
      doc_page.join("\n"))
  end
end

ApplicationSettingsAnalysis.new.execute if $PROGRAM_NAME == __FILE__
