# frozen_string_literal: true

module ErrorTracking
  class ProjectErrorTrackingSetting < ActiveRecord::Base
    include ReactiveCaching

    self.reactive_cache_key = ->(setting) { [setting.class.model_name.singular, setting.project_id] }

    belongs_to :project

    validates :api_url, length: { maximum: 255 }, public_url: true, url: { enforce_sanitization: true, ascii_only: true }, allow_nil: true

    validates :api_url, presence: true, if: :enabled

    validate :validate_api_url_path, if: :enabled

    validates :token, presence: true, if: :enabled

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-gcm'

    after_save :clear_reactive_cache!

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
        { issues: result }
      end
    end

    def list_sentry_projects
      { projects: sentry_client.list_projects }
    end

    def calculate_reactive_cache(request, opts)
      case request
      when 'list_issues'
        sentry_client.list_issues(**opts.symbolize_keys)
      end
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
      extract_slug(:project)
    end

    def organization_slug_from_api_url
      extract_slug(:organization)
    end

    def extract_slug(capture)
      return if api_url.blank?

      begin
        url = Addressable::URI.parse(api_url)
      rescue Addressable::URI::InvalidURIError
        return nil
      end

      @slug_match ||= url.path.match(%r{^/api/0/projects/+(?<organization>[^/]+)/+(?<project>[^/|$]+)}) || {}
      @slug_match[capture]
    end

    def validate_api_url_path
      return if api_url.blank?

      begin
        unless Addressable::URI.parse(api_url).path.starts_with?('/api/0/projects')
          errors.add(:api_url, 'path needs to start with /api/0/projects')
        end
      rescue Addressable::URI::InvalidURIError
      end
    end
  end
end
