# frozen_string_literal: true

module ErrorTracking
  class ProjectErrorTrackingSetting < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include ReactiveCaching
    include Gitlab::Routing

    SENTRY_API_ERROR_TYPE_BAD_REQUEST = 'bad_request_for_sentry_api'
    SENTRY_API_ERROR_TYPE_MISSING_KEYS = 'missing_keys_in_sentry_response'
    SENTRY_API_ERROR_TYPE_NON_20X_RESPONSE = 'non_20x_response_from_sentry'
    SENTRY_API_ERROR_INVALID_SIZE = 'invalid_size_of_sentry_response'

    API_URL_PATH_REGEXP = %r{
      \A
        (?<prefix>/api/0/projects/+)
        (?:
          (?<organization>[^/]+)/+
          (?<project>[^/]+)/*
        )?
      \z
    }x

    self.reactive_cache_key = ->(setting) { [setting.class.model_name.singular, setting.project_id] }
    self.reactive_cache_work_type = :external_dependency
    self.reactive_cache_hard_limit = ErrorTracking::SentryClient::RESPONSE_MEMORY_SIZE_LIMIT

    self.table_name = 'project_error_tracking_settings'

    belongs_to :project

    validates :api_url, length: { maximum: 255 }, public_url: { enforce_sanitization: true, ascii_only: true }, allow_nil: true

    validates :enabled, inclusion: { in: [true, false] }
    validates :integrated, inclusion: { in: [true, false] }

    with_options if: :sentry_enabled do
      validates :api_url, presence: { message: 'is a required field' }
      validates :token, presence: { message: 'is a required field' }
      validate :validate_api_url_path
    end

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm'

    before_validation :reset_token

    after_save :clear_reactive_cache!

    # When a user enables the integrated error tracking
    # we want to immediately provide them with a first
    # working client key so they have a DSN for Sentry SDK.
    after_save :create_client_key!

    def sentry_enabled
      enabled && !integrated_client?
    end

    def integrated_client?
      integrated
    end

    def integrated_enabled?
      enabled? && integrated_client?
    end

    def gitlab_dsn
      strong_memoize(:gitlab_dsn) do
        client_key&.sentry_dsn
      end
    end

    def api_url=(value)
      super
      clear_memoization(:api_url_slugs)
    end

    def project_name
      super || project_name_from_slug
    end

    def organization_name
      super || organization_name_from_slug
    end

    def project_slug
      project_slug_from_api_url
    end

    def organization_slug
      organization_slug_from_api_url
    end

    def self.build_api_url_from(api_host:, project_slug:, organization_slug:)
      return if api_host.blank?

      uri = Addressable::URI.parse("#{api_host}/api/0/projects/#{organization_slug}/#{project_slug}/")
      uri.path = uri.path.squeeze('/')

      uri.to_s
    rescue Addressable::URI::InvalidURIError
      api_host
    end

    def sentry_client
      strong_memoize(:sentry_client) do
        ::ErrorTracking::SentryClient.new(api_url, token)
      end
    end

    def sentry_external_url
      self.class.extract_sentry_external_url(api_url)
    end

    def list_sentry_issues(opts = {})
      with_reactive_cache_set('list_issues', opts.stringify_keys) do |result|
        result
      end
    end

    def list_sentry_projects
      handle_exceptions do
        { projects: sentry_client.projects }
      end
    end

    def issue_details(opts = {})
      with_reactive_cache('issue_details', opts.stringify_keys) do |result|
        ensure_issue_belongs_to_project!(result[:issue].project_id) if result[:issue]
        result
      end
    end

    def issue_latest_event(opts = {})
      with_reactive_cache('issue_latest_event', opts.stringify_keys) do |result|
        ensure_issue_belongs_to_project!(result[:latest_event].project_id) if result[:latest_event]
        result
      end
    end

    def update_issue(opts = {})
      issue_to_be_updated = sentry_client.issue_details(issue_id: opts[:issue_id])
      ensure_issue_belongs_to_project!(issue_to_be_updated.project_id)

      handle_exceptions do
        { updated: sentry_client.update_issue(**opts) }
      end
    end

    def calculate_reactive_cache(request, opts)
      handle_exceptions do
        case request
        when 'list_issues'
          sentry_client.list_issues(**opts.symbolize_keys)
        when 'issue_details'
          issue = sentry_client.issue_details(**opts.symbolize_keys)
          { issue: add_gitlab_issue_details(issue) }
        when 'issue_latest_event'
          {
            latest_event: sentry_client.issue_latest_event(**opts.symbolize_keys)
          }
        end
      end
    end

    def expire_issues_cache
      clear_reactive_cache_set!('list_issues')
    end

    # http://HOST/api/0/projects/ORG/PROJECT
    # ->
    # http://HOST/ORG/PROJECT
    def self.extract_sentry_external_url(url)
      url&.sub('api/0/projects/', '')
    end

    def api_host
      return if api_url.blank?

      # This returns http://example.com/
      Addressable::URI.join(api_url, '/').to_s
    end

    private

    def reset_token
      if api_url_changed? && !encrypted_token_changed?
        self.token = nil
      end
    end

    def ensure_issue_belongs_to_project!(project_id_from_api)
      raise 'The Sentry issue appers to be outside of the configured Sentry project' if Integer(project_id_from_api) != ensure_sentry_project_id!
    end

    def ensure_sentry_project_id!
      return sentry_project_id if sentry_project_id.present?

      raise("Couldn't find project: #{organization_name} / #{project_name} on Sentry") if sentry_project.nil?

      update!(sentry_project_id: sentry_project.id)
      sentry_project_id
    end

    def sentry_project
      strong_memoize(:sentry_project) do
        sentry_client.projects.find { |project| project.name == project_name && project.organization_name == organization_name }
      end
    end

    def add_gitlab_issue_details(issue)
      issue.gitlab_commit = match_gitlab_commit(issue.first_release_version)
      issue.gitlab_commit_path = project_commit_path(project, issue.gitlab_commit) if issue.gitlab_commit

      issue
    end

    def match_gitlab_commit(release_version)
      return unless release_version

      commit = project.repository.commit(release_version)

      commit&.id
    end

    def handle_exceptions
      yield
    rescue ErrorTracking::SentryClient::Error => e
      { error: e.message, error_type: SENTRY_API_ERROR_TYPE_NON_20X_RESPONSE }
    rescue ErrorTracking::SentryClient::MissingKeysError => e
      { error: e.message, error_type: SENTRY_API_ERROR_TYPE_MISSING_KEYS }
    rescue ErrorTracking::SentryClient::ResponseInvalidSizeError => e
      { error: e.message, error_type: SENTRY_API_ERROR_INVALID_SIZE }
    rescue ErrorTracking::SentryClient::BadRequestError => e
      { error: e.message, error_type: SENTRY_API_ERROR_TYPE_BAD_REQUEST }
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
      { error: 'Unexpected Error' }
    end

    def project_name_from_slug
      @project_name_from_slug ||= project_slug_from_api_url&.titleize
    end

    def organization_name_from_slug
      @organization_name_from_slug ||= organization_slug_from_api_url&.titleize
    end

    def project_slug_from_api_url
      api_url_slug(:project)
    end

    def organization_slug_from_api_url
      api_url_slug(:organization)
    end

    def api_url_slug(capture)
      slugs = strong_memoize(:api_url_slugs) { extract_api_url_slugs || {} }
      slugs[capture]
    end

    def extract_api_url_slugs
      return if api_url.blank?

      begin
        url = Addressable::URI.parse(api_url)
      rescue Addressable::URI::InvalidURIError
        return
      end

      url.path.match(API_URL_PATH_REGEXP)
    end

    def validate_api_url_path
      return if api_url.blank?

      unless api_url_slug(:prefix)
        return errors.add(:api_url, 'is invalid')
      end

      unless api_url_slug(:organization)
        errors.add(:project, 'is a required field')
      end
    end

    def client_key
      # Project can have multiple client keys.
      # However for UI simplicity we render the first active one for user.
      # In future we should make it possible to manage client keys from UI.
      # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/329596
      project.error_tracking_client_keys.active.first
    end

    def create_client_key!
      if enabled? && integrated_client? && !client_key
        project.error_tracking_client_keys.create!
      end
    end
  end
end
