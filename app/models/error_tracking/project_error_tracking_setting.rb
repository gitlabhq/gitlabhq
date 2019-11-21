# frozen_string_literal: true

module ErrorTracking
  class ProjectErrorTrackingSetting < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include ReactiveCaching

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
    }x.freeze

    self.reactive_cache_key = ->(setting) { [setting.class.model_name.singular, setting.project_id] }

    belongs_to :project

    validates :api_url, length: { maximum: 255 }, public_url: { enforce_sanitization: true, ascii_only: true }, allow_nil: true

    validates :api_url, presence: { message: 'is a required field' }, if: :enabled

    validate :validate_api_url_path, if: :enabled

    validates :token, presence: { message: 'is a required field' }, if: :enabled

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-gcm'

    after_save :clear_reactive_cache!

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
      Sentry::Client.new(api_url, token)
    end

    def sentry_external_url
      self.class.extract_sentry_external_url(api_url)
    end

    def list_sentry_issues(opts = {})
      with_reactive_cache('list_issues', opts.stringify_keys) do |result|
        result
      end
    end

    def list_sentry_projects
      { projects: sentry_client.list_projects }
    end

    def issue_details(opts = {})
      with_reactive_cache('issue_details', opts.stringify_keys) do |result|
        result
      end
    end

    def issue_latest_event(opts = {})
      with_reactive_cache('issue_latest_event', opts.stringify_keys) do |result|
        result
      end
    end

    def calculate_reactive_cache(request, opts)
      case request
      when 'list_issues'
        { issues: sentry_client.list_issues(**opts.symbolize_keys) }
      when 'issue_details'
        {
          issue: sentry_client.issue_details(**opts.symbolize_keys)
        }
      when 'issue_latest_event'
        {
          latest_event: sentry_client.issue_latest_event(**opts.symbolize_keys)
        }
      end
    rescue Sentry::Client::Error => e
      { error: e.message, error_type: SENTRY_API_ERROR_TYPE_NON_20X_RESPONSE }
    rescue Sentry::Client::MissingKeysError => e
      { error: e.message, error_type: SENTRY_API_ERROR_TYPE_MISSING_KEYS }
    rescue Sentry::Client::ResponseInvalidSizeError => e
      { error: e.message, error_type: SENTRY_API_ERROR_INVALID_SIZE }
    rescue Sentry::Client::BadRequestError => e
      { error: e.message, error_type: SENTRY_API_ERROR_TYPE_BAD_REQUEST }
    end

    # http://HOST/api/0/projects/ORG/PROJECT
    # ->
    # http://HOST/ORG/PROJECT
    def self.extract_sentry_external_url(url)
      url.sub('api/0/projects/', '')
    end

    def api_host
      return if api_url.blank?

      # This returns http://example.com/
      Addressable::URI.join(api_url, '/').to_s
    end

    private

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
  end
end
