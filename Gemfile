# frozen_string_literal: true

source 'https://rubygems.org'

if ENV.fetch('BUNDLER_CHECKSUM_VERIFICATION_OPT_IN', 'false') != 'false' # this verification is still experimental
  $LOAD_PATH.unshift(File.expand_path("vendor/gems/bundler-checksum/lib", __dir__))
  require 'bundler-checksum'
  BundlerChecksum.patch!
end

# Please see https://docs.gitlab.com/ee/development/feature_categorization/#gemfile
ignore_feature_category = Module.new do
  def gem(*arguments, feature_category: nil, **keyword_arguments) # rubocop:disable Lint/UnusedMethodArgument -- Ignoring feature_category intentionally
    super(*arguments, **keyword_arguments)
  end
end

extend ignore_feature_category

gem 'bundler-checksum', '~> 0.1.0', path: 'vendor/gems/bundler-checksum', require: false, feature_category: :shared

# NOTE: When incrementing the major or minor version here, also increment activerecord_version
# in vendor/gems/attr_encrypted/attr_encrypted.gemspec until we resolve
# https://gitlab.com/gitlab-org/gitlab/-/issues/375713
#
# See https://docs.gitlab.com/ee/development/gemfile.html#upgrade-rails for guidelines when upgrading Rails

gem 'rails', '~> 7.1.5.1', feature_category: :shared

gem 'activerecord-gitlab', path: 'gems/activerecord-gitlab', feature_category: :shared
# This can be dropped after upgrading to Rails 7.2: https://github.com/rails/rails/pull/49674
gem 'mutex_m', '~> 0.3', feature_category: :shared
# Need by Rails
gem 'drb', '~> 2.2', feature_category: :shared

gem 'bootsnap', '~> 1.18.3', require: false, feature_category: :shared

# Avoid the precompiled native gems because Omnibus needs to build this to ensure
# LD_LIBRARY_PATH is correct: https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7730
if RUBY_PLATFORM.include?('darwin')
  gem 'ffi', '~> 1.17', feature_category: :shared
else
  gem 'ffi', '~> 1.17', force_ruby_platform: true, feature_category: :shared
end

gem 'openssl', '~> 3.0', feature_category: :shared

gem 'gitlab-safe_request_store', path: 'gems/gitlab-safe_request_store', feature_category: :shared

# GitLab Monorepo Gems
group :monorepo do
  gem 'gitlab-utils', path: 'gems/gitlab-utils', feature_category: :shared
end

gem 'gitlab-backup-cli', path: 'gems/gitlab-backup-cli', require: 'gitlab/backup/cli', feature_category: :backup_restore

gem 'gitlab-secret_detection', '< 1.0', feature_category: :secret_detection

# Responders respond_to and respond_with
gem 'responders', '~> 3.0', feature_category: :shared

gem 'sprockets', '~> 3.7.0', feature_category: :shared
gem 'sprockets-rails', '~>  3.5.1', feature_category: :shared

gem 'view_component', '~> 3.21.0', feature_category: :shared

# Supported DBs
gem 'pg', '~> 1.5.6', feature_category: :database

gem 'rugged', '~> 1.6', feature_category: :gitaly

gem 'faraday', '~> 2', feature_category: :shared
gem 'faraday-retry', '~> 2', feature_category: :shared
# Logger is a dependency of Faraday, but Logger 1.6.0 does not work with Chef.
gem 'logger', '~> 1.6.0', feature_category: :shared

gem 'marginalia', '~> 1.11.1', feature_category: :database

# Authorization
gem 'declarative_policy', '~> 1.1.0', feature_category: :shared

# For source code paths mapping
gem 'coverband', '6.1.5', require: false, feature_category: :shared

# Authentication libraries
gem 'devise', '~> 4.9.3', feature_category: :system_access
gem 'devise-pbkdf2-encryptable', '~> 0.0.0', path: 'vendor/gems/devise-pbkdf2-encryptable',
  feature_category: :system_access
gem 'bcrypt', '~> 3.1', '>= 3.1.14', feature_category: :system_access
gem 'doorkeeper', '~> 5.8', '>= 5.8.1', feature_category: :system_access
gem 'doorkeeper-openid_connect', '~> 1.8.10', feature_category: :system_access
gem 'doorkeeper-device_authorization_grant', '~> 1.0.0', feature_category: :system_access
gem 'rexml', '~> 3.4.0', feature_category: :shared
gem 'ruby-saml', '~> 1.18', feature_category: :system_access
gem 'omniauth-saml', '~> 2.2.1', feature_category: :system_access
gem 'omniauth', '~> 2.1.0', feature_category: :system_access
gem 'omniauth-auth0', '~> 3.1', feature_category: :system_access
gem 'omniauth-azure-activedirectory-v2', '~> 2.0', feature_category: :system_access
gem 'omniauth-alicloud', '~> 3.0.0', feature_category: :system_access
gem 'omniauth-github', '2.0.1', feature_category: :system_access
# See vendor/gems/omniauth-gitlab/README.md
gem 'omniauth-gitlab', '~> 4.0.0', path: 'vendor/gems/omniauth-gitlab', feature_category: :system_access
gem 'omniauth-google-oauth2', '~> 1.1', feature_category: :system_access
gem 'omniauth-oauth2-generic', '~> 0.2.2', feature_category: :system_access
gem 'omniauth-shibboleth-redux', '~> 2.0', require: 'omniauth-shibboleth', feature_category: :system_access
# See vendor/gems/omniauth_crowd/README.md
gem 'omniauth_crowd', '~> 2.4.0', path: 'vendor/gems/omniauth_crowd', feature_category: :system_access
gem 'omniauth_openid_connect', '~> 0.8.0', feature_category: :system_access
# Locked until Ruby 3.0 upgrade since upgrading will pull in an updated net-smtp gem.
# See https://docs.gitlab.com/ee/development/emails.html#rationale.
gem 'openid_connect', '~> 2.3.0', feature_category: :system_access
# See gem README.md
gem 'omniauth-salesforce', '~> 1.0.5', path: 'vendor/gems/omniauth-salesforce', feature_category: :system_access
gem 'omniauth-atlassian-oauth2', '~> 0.2.0', feature_category: :system_access
gem 'rack-oauth2', '~> 2.2.1', feature_category: :system_access
gem 'jwt', '~> 2.9.3', feature_category: :system_access

# Kerberos authentication. EE-only
gem 'gssapi', '~> 1.3.1', group: :kerberos, feature_category: :system_access
gem 'timfel-krb5-auth', '~> 0.8', group: :kerberos, feature_category: :system_access

# Spam and anti-bot protection
gem 'recaptcha', '~> 5.12', require: 'recaptcha/rails', feature_category: :insider_threat
gem 'akismet', '~> 3.0', feature_category: :insider_threat
gem 'invisible_captcha', '~> 2.1.0', feature_category: :insider_threat

# Two-factor authentication
gem 'devise-two-factor', '~> 4.1.1', feature_category: :system_access
gem 'rqrcode', '~> 2.2', feature_category: :system_access

gem 'attr_encrypted', '~> 3.2.4', path: 'vendor/gems/attr_encrypted', feature_category: :shared

# GitLab Pages
gem 'validates_hostname', '~> 1.0.13', feature_category: :pages
gem 'rubyzip', '~> 2.3.2', require: 'zip', feature_category: :pages
# GitLab Pages letsencrypt support
gem 'acme-client', '~> 2.0.19', feature_category: :pages

# Browser detection
gem 'browser', '~> 5.3.1', feature_category: :shared

# OS detection for usage ping
gem 'ohai', '~> 18.1', feature_category: :product_analytics

# GPG
gem 'gpgme', '~> 2.0.24', feature_category: :source_code_management

# LDAP Auth
# GitLab fork with several improvements to original library. For full list of changes
# see https://github.com/intridea/omniauth-ldap/compare/master...gitlabhq:master
gem 'gitlab_omniauth-ldap', '~> 2.2.0', require: 'omniauth-ldap', feature_category: :system_access
gem 'net-ldap', '~> 0.17.1', feature_category: :system_access

# API
gem 'grape', '~> 2.0.0', feature_category: :api
gem 'grape-entity', '~> 1.0.1', feature_category: :api
gem 'grape-swagger', '~> 2.1.2', group: [:development, :test], feature_category: :api
gem 'grape-swagger-entity', '~> 0.5.5', group: [:development, :test], feature_category: :api
gem 'grape-path-helpers', '~> 2.0.1', feature_category: :api
gem 'rack-cors', '~> 2.0.1', require: 'rack/cors', feature_category: :shared

# GraphQL API
gem 'graphql', '2.4.13', feature_category: :api
gem 'graphql-docs', '~> 5.0.0', group: [:development, :test], feature_category: :api
gem 'apollo_upload_server', '~> 2.1.6', feature_category: :api

# Cells
gem 'gitlab-topology-service-client', '~> 0.1',
  path: 'vendor/gems/gitlab-topology-service-client',
  feature_category: :cell

# Duo Workflow
gem 'gitlab-duo-workflow-service-client', '~> 0.1',
  path: 'vendor/gems/gitlab-duo-workflow-service-client',
  feature_category: :duo_workflow

# Generate Fake data
gem 'ffaker', '~> 2.24', feature_category: :shared

gem 'hashie', '~> 5.0.0', feature_category: :shared

# Pagination
gem 'kaminari', '~> 1.2.2', feature_category: :shared

# HAML
gem 'hamlit', '~> 2.15.0', feature_category: :shared

# Files attachments
gem 'carrierwave', '~> 1.3', feature_category: :shared
gem 'mini_magick', '~> 4.12', feature_category: :shared

# PDF generation
gem 'prawn', feature_category: :vulnerability_management
gem 'prawn-svg', feature_category: :vulnerability_management

# for backups
gem 'fog-aws', '~> 3.26', feature_category: :shared
# Locked until fog-google resolves https://github.com/fog/fog-google/issues/421.
# Also see config/initializers/fog_core_patch.rb.
gem 'fog-core', '= 2.1.0', feature_category: :shared
gem 'fog-google', '~> 1.24.1', require: 'fog/google', feature_category: :shared
gem 'fog-local', '~> 0.8', feature_category: :shared
# NOTE:
# the fog-aliyun gem since v0.4 pulls in aliyun-sdk transitively, which monkey-patches
# the rest-client gem to drop the Content-Length header field for chunked transfers,
# which may have knock-on effects on other features using `RestClient`.
# We may want to update this dependency if this is ever addressed upstream, e.g. via
# https://github.com/aliyun/aliyun-oss-ruby-sdk/pull/93
gem 'fog-aliyun', '~> 0.4', feature_category: :shared
gem 'gitlab-fog-azure-rm', '~> 2.2.0', require: 'fog/azurerm', feature_category: :shared

# for Google storage

# Need this specific version of google-apis-storage_v1 so that fog-google will utilize the updated list_objects with
# match_glob support in google-apis-core 0.11.1. Because of this we also have to bump google-cloud-storage to 1.45.0.
gem 'google-apis-storage_v1', '~> 0.29', feature_category: :shared
gem 'google-cloud-storage', '~> 1.45.0', feature_category: :shared
# We need >= 0.11.1 because that's when match_glob support is added to list_objects
gem 'google-apis-core', '~> 0.11.0', '>= 0.11.1', feature_category: :shared
gem 'google-apis-compute_v1', '~> 0.57.0', feature_category: :shared
gem 'google-apis-container_v1', '~> 0.43.0', feature_category: :shared
gem 'google-apis-container_v1beta1', '~> 0.43.0', feature_category: :shared
gem 'google-apis-cloudbilling_v1', '~> 0.22.0', feature_category: :shared
gem 'google-apis-cloudresourcemanager_v1', '~> 0.31.0', feature_category: :shared
gem 'google-apis-iam_v1', '~> 0.36.0', feature_category: :shared
gem 'google-apis-serviceusage_v1', '~> 0.28.0', feature_category: :shared
gem 'google-apis-sqladmin_v1beta4', '~> 0.41.0', feature_category: :shared
gem 'google-apis-androidpublisher_v3', '~> 0.34.0', feature_category: :shared

gem 'googleauth', '~> 1.8.1', feature_category: :shared
gem 'google-cloud-artifact_registry-v1', '~> 0.11.0', feature_category: :shared
gem 'google-cloud-compute-v1', '~> 2.6.0', feature_category: :shared

# Seed data
gem 'seed-fu', '~> 2.3.7', feature_category: :shared

# Search
gem 'elasticsearch-model', '~> 7.2', feature_category: :global_search
gem 'elasticsearch-rails', '~> 7.2', require: 'elasticsearch/rails/instrumentation', feature_category: :global_search
gem 'elasticsearch-api', '7.17.11', feature_category: :global_search
gem 'aws-sdk-core', '~> 3.223.0', feature_category: :global_search
gem 'aws-sdk-cloudformation', '~> 1', feature_category: :global_search
gem 'aws-sdk-s3', '~> 1.185.0', feature_category: :global_search
gem 'faraday-typhoeus', '~> 1.1', feature_category: :global_search
gem 'faraday_middleware-aws-sigv4', '~> 1.0.1', feature_category: :global_search
# Used with Elasticsearch to support http keep-alive connections
gem 'typhoeus', '~> 1.4.0', feature_category: :global_search

gem 'gitlab-active-context', path: 'gems/gitlab-active-context', require: 'active_context',
  feature_category: :global_search

# Markdown and HTML processing
gem 'html-pipeline', '~> 2.14.3', feature_category: :markdown
gem 'deckar01-task_list', '2.3.4', feature_category: :markdown
gem 'gitlab-markup', '~> 2.0.0', require: 'github/markup', feature_category: :markdown
gem 'commonmarker', '~> 0.23.10', feature_category: :markdown
gem 'kramdown', '~> 2.5.0', feature_category: :markdown
gem 'RedCloth', '~> 4.3.3', feature_category: :markdown
gem 'org-ruby', '~> 0.9.12', feature_category: :markdown
gem 'creole', '~> 0.5.0', feature_category: :markdown
gem 'wikicloth', '0.8.1', feature_category: :markdown
gem 'asciidoctor', '~> 2.0.18', feature_category: :markdown
gem 'asciidoctor-include-ext', '~> 0.4.0', require: false, feature_category: :markdown
gem 'asciidoctor-plantuml', '~> 0.0.16', feature_category: :markdown
gem 'asciidoctor-kroki', '~> 0.10.0', require: false, feature_category: :markdown
gem 'rouge', '~> 4.5.0', feature_category: :shared
gem 'truncato', '~> 0.7.13', feature_category: :team_planning
gem 'nokogiri', '~> 1.18', feature_category: :shared
gem 'gitlab-glfm-markdown', '~> 0.0.30', feature_category: :markdown
gem 'tanuki_emoji', '~> 0.13', feature_category: :markdown
gem 'unicode-emoji', '~> 4.0', feature_category: :markdown

# Calendar rendering
gem 'icalendar', '~> 2.10.1', feature_category: :team_planning

# Diffs
gem 'diffy', '~> 3.4', feature_category: :shared
gem 'diff_match_patch', '~> 0.1.0', path: 'vendor/gems/diff_match_patch', feature_category: :team_planning

# Application server
gem 'rack', '~> 2.2.9', feature_category: :shared
# https://github.com/zombocom/rack-timeout/blob/master/README.md#rails-apps-manually
gem 'rack-timeout', '~> 0.7.0', require: 'rack/timeout/base', feature_category: :shared

group :puma do
  gem 'puma', '= 6.5.0', require: false, feature_category: :shared
  gem 'sd_notify', '~> 0.1.0', require: false, feature_category: :shared
end

# State machine
gem 'state_machines-activerecord', '~> 0.8.0', feature_category: :shared

# Background jobs
gem 'sidekiq', path: 'vendor/gems/sidekiq', require: 'sidekiq', feature_category: :scalability
gem 'sidekiq-cron', '~> 1.12.0', feature_category: :scalability
gem 'gitlab-sidekiq-fetcher',
  path: 'vendor/gems/sidekiq-reliable-fetch',
  require: 'sidekiq-reliable-fetch',
  feature_category: :scalability

# Cron Parser
gem 'fugit', '~> 1.11.1', feature_category: :continuous_integration

# HTTP requests
gem 'httparty', '~> 0.22.0', feature_category: :shared

# Colored output to console
gem 'rainbow', '~> 3.0', feature_category: :shared

# Progress bar
gem 'ruby-progressbar', '~> 1.10', feature_category: :shared

# Linear-time regex library for untrusted regular expressions
gem 're2', '~> 2.15', feature_category: :shared

# Misc

gem 'semver_dialects', '~> 3.7', feature_category: :software_composition_analysis
gem 'version_sorter', '~> 2.3', feature_category: :shared
gem 'csv_builder', path: 'gems/csv_builder', feature_category: :shared

# Export Ruby Regex to Javascript
gem 'js_regex', '~> 3.8', feature_category: :shared

# User agent parsing
gem 'device_detector', feature_category: :shared

# Redis
gem 'redis', '~> 5.4.0', feature_category: :redis
gem 'redis-clustering', '~> 5.4.0', feature_category: :redis
gem 'connection_pool', '~> 2.4', feature_category: :shared

# Redis session store
gem 'redis-actionpack', '~> 5.5.0', feature_category: :redis

# Discord integration
gem 'discordrb-webhooks', '~> 3.5', require: false, feature_category: :integrations

# Jira integration
gem 'jira-ruby', '~> 2.3.0', feature_category: :integrations
gem 'atlassian-jwt', '~> 0.2.1', feature_category: :integrations

# Slack integration
gem 'slack-messenger', '~> 2.3.5', feature_category: :integrations

# FogBugz integration
gem 'ruby-fogbugz', '~> 0.3.0', feature_category: :importers

# Kubernetes integration
gem 'kubeclient', '~> 4.11.0', feature_category: :shared

# AI
gem 'circuitbox', '2.0.0', feature_category: :ai_abstraction_layer

# Sanitize user input
gem 'sanitize', '~> 6.0.2', feature_category: :shared
gem 'babosa', '~> 2.0', feature_category: :shared

# Sanitizes SVG input
gem 'loofah', '~> 2.24.0', feature_category: :shared

# Used to provide license templates
gem 'licensee', '~> 9.16', feature_category: :shared

# Detect and convert string character encoding
gem 'charlock_holmes', '~> 0.7.9', feature_category: :shared

# Detect mime content type from content
gem 'ruby-magic', '~> 0.6', feature_category: :shared

# Faster blank
gem 'fast_blank', '~> 1.0.1', feature_category: :shared

# Parse time & duration
gem 'gitlab-chronic', '~> 0.10.5', feature_category: :shared
gem 'gitlab_chronic_duration', '~> 0.12', feature_category: :shared

gem 'rack-proxy', '~> 0.7.7', feature_category: :shared

gem 'cssbundling-rails', '1.4.3', feature_category: :shared
gem 'terser', '1.0.2', feature_category: :shared

gem 'click_house-client', path: 'gems/click_house-client', require: 'click_house/client', feature_category: :database
gem 'addressable', '~> 2.8', feature_category: :shared
gem 'gon', '~> 6.4.0', feature_category: :shared
gem 'request_store', '~> 1.7.0', feature_category: :shared
gem 'base32', '~> 0.3.0', feature_category: :shared
gem 'gitlab-license', '~> 2.6', feature_category: :shared

# Protect against bruteforcing
gem 'rack-attack', '~> 6.7.0', feature_category: :shared

# Sentry integration
gem 'sentry-ruby', '~> 5.23.0', feature_category: :observability
gem 'sentry-rails', '~> 5.23.0', feature_category: :observability
gem 'sentry-sidekiq', '~> 5.23.0', feature_category: :observability

# PostgreSQL query parsing
#
gem 'pg_query', '~> 6.1.0', feature_category: :database

gem 'gitlab-schema-validation', path: 'gems/gitlab-schema-validation', feature_category: :shared
gem 'gitlab-http', path: 'gems/gitlab-http', feature_category: :shared

gem 'premailer-rails', '~> 1.12.0', feature_category: :notifications
gem 'gitlab-labkit', '~> 0.37.0', feature_category: :shared
gem 'thrift', '>= 0.16.0', feature_category: :shared

# I18n
gem 'rails-i18n', '~> 7.0', '>= 7.0.9', feature_category: :internationalization
gem 'gettext_i18n_rails', '~> 1.13.0', feature_category: :internationalization
gem 'gettext', '~> 3.5', '>= 3.5.1',
  require: false,
  group: [:development, :test],
  feature_category: :internationalization

gem 'batch-loader', '~> 2.0.5', feature_category: :shared

gem 'tty-prompt', '~> 0.23', require: false, feature_category: :shared

# Perf bar
gem 'peek', '~> 1.1', feature_category: :shared

# Google Cloud Profiler support
gem 'cloud_profiler_agent', '~> 0.0.0', path: 'vendor/gems/cloud_profiler_agent', require: false,
  feature_category: :shared

# Snowplow events trackin
gem 'snowplow-tracker', '~> 0.8.0', feature_category: :product_analytics

# Metrics
gem 'webrick', '~> 1.9.0', require: false, feature_category: :shared
gem 'prometheus-client-mmap', '~> 1.2.8', require: 'prometheus/client', feature_category: :shared

# Event-driven reactor for Ruby
# Required manually in config/initializers/require_async_gem
gem 'async', '~> 2.23.0', require: false, feature_category: :shared

# Security report schemas used to validate CI job artifacts of security jobs
gem 'gitlab-security_report_schemas', '0.1.2.min15.0.0.max15.2.1', feature_category: :vulnerability_management

# OpenTelemetry
group :opentelemetry do
  # Core OpenTelemetry gems
  gem 'opentelemetry-sdk', feature_category: :observability
  gem 'opentelemetry-exporter-otlp', feature_category: :observability

  # OpenTelemetry gems selected from full set in `opentelemetry-instrumentation-all` metagem
  gem 'opentelemetry-instrumentation-active_support', feature_category: :observability
  gem 'opentelemetry-instrumentation-action_pack', feature_category: :observability
  gem 'opentelemetry-instrumentation-active_job', feature_category: :observability
  gem 'opentelemetry-instrumentation-active_record', feature_category: :observability
  gem 'opentelemetry-instrumentation-action_view', feature_category: :observability
  gem 'opentelemetry-instrumentation-aws_sdk', feature_category: :observability
  gem 'opentelemetry-instrumentation-http', feature_category: :observability
  gem 'opentelemetry-instrumentation-concurrent_ruby', feature_category: :observability
  gem 'opentelemetry-instrumentation-ethon', feature_category: :observability
  gem 'opentelemetry-instrumentation-excon', feature_category: :observability
  gem 'opentelemetry-instrumentation-faraday', feature_category: :observability
  gem 'opentelemetry-instrumentation-grape', feature_category: :observability
  gem 'opentelemetry-instrumentation-graphql', feature_category: :observability
  gem 'opentelemetry-instrumentation-http_client', feature_category: :observability
  gem 'opentelemetry-instrumentation-net_http', feature_category: :observability
  gem 'opentelemetry-instrumentation-pg', feature_category: :observability
  gem 'opentelemetry-instrumentation-rack', feature_category: :observability
  gem 'opentelemetry-instrumentation-rails', feature_category: :observability
  gem 'opentelemetry-instrumentation-rake', feature_category: :observability
  gem 'opentelemetry-instrumentation-redis', feature_category: :observability
  gem 'opentelemetry-instrumentation-sidekiq', feature_category: :observability
end

gem 'warning', '~> 1.5.0', feature_category: :shared

group :development do
  gem 'lefthook', '~> 1.11.0', require: false, feature_category: :tooling
  gem 'rubocop', feature_category: :tooling

  gem 'solargraph', '~> 0.54.0', require: false, feature_category: :shared
  gem 'solargraph-rspec', '~> 0.5.1', require: false, feature_category: :shared

  gem 'letter_opener_web', '~> 3.0.0', feature_category: :shared
  gem 'lookbook', '~> 2.3', feature_category: :shared

  # Better errors handler
  gem 'better_errors', '~> 2.10.1', feature_category: :shared

  gem 'sprite-factory', '~> 1.7', feature_category: :shared

  gem 'listen', '~> 3.7', feature_category: :shared

  gem 'ruby-lsp', "~> 0.23.0", require: false, feature_category: :tooling

  gem 'ruby-lsp-rails', "~> 0.3.6", feature_category: :tooling

  gem 'ruby-lsp-rspec', "~> 0.1.10", require: false, feature_category: :tooling

  gem 'gdk-toogle', '~> 0.9', '>= 0.9.5', require: 'toogle', feature_category: :tooling

  # Used by
  # * `lib/tasks/gitlab/security/update_banned_ssh_keys.rake`
  # * `lib/tasks/gitlab/db/migration_squash.rake`
  gem 'git', '~> 1.8', feature_category: :shared
end

group :development, :test do
  gem 'deprecation_toolkit', '~> 2.2.3', require: false, feature_category: :shared
  gem 'bullet', '~> 7.2.0', feature_category: :shared
  gem 'parser', '= 3.3.8.0', feature_category: :shared
  gem 'pry-byebug', feature_category: :shared
  gem 'pry-rails', '~> 0.3.9', feature_category: :shared
  gem 'pry-shell', '~> 0.6.4', feature_category: :shared

  gem 'awesome_print', require: false, feature_category: :shared

  gem 'database_cleaner-active_record', '~> 2.2.0', feature_category: :database
  gem 'rspec-rails', '~> 7.0.0', feature_category: :shared
  gem 'factory_bot_rails', '~> 6.4.3', feature_category: :tooling

  # Prevent occasions where minitest is not bundled in packaged versions of ruby (see #3826)
  gem 'minitest', '~> 5.11.0', feature_category: :shared

  gem 'spring', '~> 4.3.0', feature_category: :shared
  gem 'spring-commands-rspec', '~> 1.0.4', feature_category: :shared

  gem 'gitlab-styles', '~> 13.1.0', feature_category: :tooling, require: false
  gem 'haml_lint', '~> 0.58', feature_category: :tooling, require: false

  # Benchmarking & profiling
  gem 'benchmark-ips', '~> 2.14.0', require: false, feature_category: :shared
  gem 'benchmark-memory', '~> 0.1', require: false, feature_category: :shared

  # Profiling data from CI/CD pipelines
  gem 'influxdb-client', '~> 3.1', require: false, feature_category: :tooling

  gem 'knapsack', '~> 4.0.0', feature_category: :tooling
  gem 'gitlab-crystalball', '~> 0.7.2', require: false, feature_category: :tooling
  gem 'test_file_finder', '~> 0.3.1', feature_category: :tooling

  gem 'simple_po_parser', '~> 1.1.6', require: false, feature_category: :shared

  gem 'png_quantizator', '~> 0.2.1', require: false, feature_category: :shared

  gem 'parallel', '~> 1.19', require: false, feature_category: :shared

  gem 'sigdump', '~> 0.2.4', require: 'sigdump/setup', feature_category: :shared

  gem 'pact', '~> 1.64', feature_category: :shared

  # For now we only use vite in development / test, and not for production builds
  # See: https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/106
  gem 'vite_rails', '~> 3.0.17', feature_category: :shared
  gem 'vite_ruby', '~> 3.9.0', feature_category: :shared

  gem 'gitlab-housekeeper', path: 'gems/gitlab-housekeeper', feature_category: :tooling

  gem 'yard', '~> 0.9', require: false, feature_category: :tooling
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 4.9.0', require: false, feature_category: :tooling
end

group :development, :test, :coverage do
  gem 'simplecov', '~> 0.22', require: false, feature_category: :tooling
  gem 'simplecov-lcov', '~> 0.8.0', require: false, feature_category: :tooling
  gem 'simplecov-cobertura', '~> 2.1.0', require: false, feature_category: :tooling
  gem 'undercover', '~> 0.6.0', require: false, feature_category: :tooling
end

# Gems required in omnibus-gitlab pipeline
group :development, :test, :omnibus do
  gem 'license_finder', '~> 7.0', require: false, feature_category: :shared
end

# Gems required in various pipelines
group :development, :test, :monorepo do
  gem 'gitlab-rspec', path: 'gems/gitlab-rspec', feature_category: :shared
  gem 'gitlab-rspec_flaky', path: 'gems/gitlab-rspec_flaky', feature_category: :tooling
end

group :test do
  gem 'rspec-retry', '~> 0.6.2', feature_category: :tooling
  gem 'rspec_profiling', '~> 0.0.9', feature_category: :tooling
  gem 'rspec-benchmark', '~> 0.6.0', feature_category: :tooling
  gem 'rspec-parameterized', '~> 1.0', '>= 1.0.2', require: false, feature_category: :tooling
  gem 'os', '~> 1.1', '>= 1.1.4', feature_category: :tooling

  gem 'capybara', '~> 3.40', feature_category: :test_platform
  gem 'capybara-screenshot', '~> 1.0.26', feature_category: :test_platform
  gem 'selenium-webdriver', '~> 4.21', '>= 4.21.1', feature_category: :test_platform

  gem 'graphlyte', '~> 1.0.0', feature_category: :shared

  gem 'shoulda-matchers', '~> 6.4.0', require: false, feature_category: :shared
  gem 'email_spec', '~> 2.3.0', feature_category: :shared
  gem 'webmock', '~> 3.25.0', feature_category: :shared
  gem 'rails-controller-testing', feature_category: :shared
  gem 'concurrent-ruby', '~> 1.1', feature_category: :shared
  gem 'test-prof', '~> 1.4.0', feature_category: :tooling
  gem 'rspec_junit_formatter', feature_category: :shared
  gem 'guard-rspec', feature_category: :shared
  gem 'axe-core-rspec', '~> 4.10.0', feature_category: :tooling
  gem 'state_machines-rspec', '~> 0.6', feature_category: :shared

  # Moved in `test` because https://gitlab.com/gitlab-org/gitlab/-/issues/217527
  gem 'derailed_benchmarks', require: false, feature_category: :shared

  gem 'gitlab_quality-test_tooling', '~> 2.10.0', require: false, feature_category: :tooling
end

gem 'octokit', '~> 9.0', feature_category: :importers
# Needed by octokit: https://github.com/octokit/octokit.rb/pull/1688
gem 'faraday-multipart', '~> 1.0', feature_category: :importers

gem 'gitlab-mail_room', '~> 0.0.24', require: 'mail_room', feature_category: :shared

gem 'email_reply_trimmer', '~> 0.1', feature_category: :shared
gem 'html2text', feature_category: :shared

gem 'stackprof', '~> 0.2.26', require: false, feature_category: :shared
gem 'rbtrace', '~> 0.4', require: false, feature_category: :shared
gem 'memory_profiler', '~> 1.0', require: false, feature_category: :shared
gem 'activerecord-explain-analyze', '~> 0.1', require: false, feature_category: :shared

# OAuth
gem 'oauth2', '~> 2.0', feature_category: :system_access

# Health check
gem 'health_check', '~> 3.0', feature_category: :shared

# System information
gem 'vmstat', '~> 2.3.0', feature_category: :shared
gem 'sys-filesystem', '~> 1.4.3', feature_category: :shared

# NTP client
gem 'net-ntp', feature_category: :shared

# SSH keys support
gem 'ssh_data', '~> 1.3', feature_category: :shared

# Spamcheck GRPC protocol definitions
gem 'spamcheck', '~> 1.3.0', feature_category: :insider_threat

# Gitaly GRPC protocol definitions
gem 'gitaly', '~> 17.8.0', feature_category: :gitaly

# KAS GRPC protocol definitions
gem 'gitlab-kas-grpc', '~> 17.11.0', feature_category: :deployment_management

# Lock the version before issues below are resolved:
# https://gitlab.com/gitlab-org/gitlab/-/issues/473169#note_2028352939
# Or we can upgrade to a more recent version as long as we can confirm
# that it doesn't have the same issues.
gem 'grpc', '= 1.63.0', feature_category: :shared

gem 'google-protobuf', '~> 3.25', '>= 3.25.3', feature_category: :shared

gem 'toml-rb', '~> 2.2.0', feature_category: :shared

# Feature toggles
gem 'flipper', '~> 0.28.0', feature_category: :shared
gem 'flipper-active_record', '~> 0.28.0', feature_category: :shared
gem 'flipper-active_support_cache_store', '~> 0.28.0', feature_category: :shared
gem 'unleash', '~> 3.2.2', feature_category: :shared
gem 'gitlab-experiment', '~> 0.9.1', feature_category: :shared

# Structured logging
gem 'lograge', '~> 0.5', feature_category: :shared
gem 'grape_logging', '~> 1.8', '>= 1.8.4', feature_category: :api

# DNS Lookup
gem 'gitlab-net-dns', '~> 0.12.0', feature_category: :shared

# Countries list
gem 'countries', '~> 4.0.0', feature_category: :shared

gem 'retriable', '~> 3.1.2', feature_category: :shared

# LRU cache
gem 'lru_redux', feature_category: :shared

# Locked as long as quoted-printable encoding issues are not resolved
# Monkey-patched in `config/initializers/mail_encoding_patch.rb`
# See https://gitlab.com/gitlab-org/gitlab/issues/197386
#
# `config/initializers/mail_starttls_patch.rb` has also been patched to
# fix STARTTLS handling until https://github.com/mikel/mail/pull/1536 is
# released.
gem 'mail', '= 2.8.1', feature_category: :shared
gem 'mail-smtp_pool', '~> 0.1.0', path: 'vendor/gems/mail-smtp_pool', require: false, feature_category: :shared

gem 'microsoft_graph_mailer', '~> 0.1.0', path: 'vendor/gems/microsoft_graph_mailer', feature_category: :shared

# File encryption
gem 'lockbox', '~> 1.3.0', feature_category: :shared

# Email validation
gem 'valid_email', '~> 0.1', feature_category: :shared

# JSON
gem 'jsonb_accessor', '~> 1.4', feature_category: :shared
gem 'json', '~> 2.11.0', feature_category: :shared
gem 'json_schemer', '~> 2.3.0', feature_category: :shared
gem 'oj', '~> 3.16.0', '>=3.16.10', feature_category: :shared
gem 'oj-introspect', '~> 0.8', feature_category: :shared
gem 'multi_json', '~> 1.14.1', feature_category: :shared
gem 'yajl-ruby', '~> 1.4.3', require: 'yajl', feature_category: :shared

gem 'webauthn', '~> 3.0', feature_category: :shared

# IPAddress utilities
gem 'ipaddress', '~> 0.8.3', feature_category: :shared

gem 'parslet', '~> 1.8', feature_category: :shared

gem 'ipynbdiff', path: 'gems/ipynbdiff', require: 'ipynb_diff', feature_category: :shared

gem 'ed25519', '~> 1.4.0', feature_category: :shared

# Error Tracking OpenAPI client
# See https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/rake_tasks.md#update-openapi-client-for-error-tracking-feature
gem 'error_tracking_open_api', path: 'gems/error_tracking_open_api', feature_category: :shared

# Vulnerability advisories
gem 'cvss-suite', '~> 3.3.0', require: 'cvss_suite', feature_category: :software_composition_analysis

# Work with RPM packages
gem 'arr-pm', '~> 0.0.12', feature_category: :package_registry

# Remote Development
gem 'devfile', '~> 0.4.4', feature_category: :workspaces

# Apple plist parsing
gem 'CFPropertyList', '~> 3.0.0', feature_category: :mobile_devops
gem 'app_store_connect', feature_category: :mobile_devops

# For phone verification
gem 'telesignenterprise', '~> 2.2', feature_category: :insider_threat

# BufferedIO patch
# Updating this version will require updating scripts/allowed_warnings.txt
gem 'net-protocol', '~> 0.1.3', feature_category: :shared
gem "nkf", "~> 0.2.0", feature_category: :shared

# This is locked to 0.6.0 because we patch Net::HTTP#connect in
# gems/gitlab-http/lib/net_http/connect_patch.rb.
# It can be upgraded but care must be taken to preserve the patch.
gem 'net-http', '= 0.6.0', feature_category: :shared
# This is locked to 0.13.0 because the default parser changes from RFC2396 to RFC3986,
# which can be removed after Rails 7.2 upgrade
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173142#note_2277952450
gem 'uri', '= 0.13.2', feature_category: :shared

gem 'duo_api', '~> 1.3', feature_category: :system_access

gem 'gitlab-sdk', '~> 0.3.0', feature_category: :application_instrumentation

gem 'paper_trail', '~> 16.0', feature_category: :shared

gem "i18n_data", "~> 0.13.1", feature_category: :system_access

gem "gitlab-cloud-connector", "~> 1.11", require: 'gitlab/cloud_connector', feature_category: :cloud_connector
