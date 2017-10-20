module Gitlab
  module Geo
    OauthApplicationUndefinedError = Class.new(StandardError)
    GeoNodeNotFoundError = Class.new(StandardError)

    CACHE_KEYS = %i(
      geo_primary_node
      geo_secondary_nodes
      geo_node_enabled
      geo_node_primary
      geo_node_secondary
      geo_oauth_application
    ).freeze

    SECONDARY_JOBS = %i(repository_sync_job file_download_job).freeze

    FDW_SCHEMA = 'gitlab_secondary'.freeze

    def self.current_node
      self.cache_value(:geo_node_current) do
        GeoNode.find_by(host: Gitlab.config.gitlab.host,
                        port: Gitlab.config.gitlab.port,
                        relative_url_root: Gitlab.config.gitlab.relative_url_root)
      end
    end

    def self.primary_node
      self.cache_value(:geo_primary_node) { GeoNode.find_by(primary: true) }
    end

    def self.secondary_nodes
      self.cache_value(:geo_secondary_nodes) { GeoNode.where(primary: false) }
    end

    def self.enabled?
      GeoNode.connected? && self.cache_value(:geo_node_enabled) { GeoNode.exists? }
    rescue => e
      # We can't use the actual classes in rescue because we load only one of them based on database supported
      raise e unless %w(PG::UndefinedTable Mysql2::Error).include? e.class.name

      false
    end

    def self.current_node_enabled?
      # No caching of the enabled! If we cache it and an admin disables
      # this node, an active Geo::RepositorySyncWorker would keep going for up
      # to max run time after the node was disabled.
      Gitlab::Geo.current_node.reload.enabled?
    end

    def self.geo_database_configured?
      Rails.configuration.respond_to?(:geo_database)
    end

    def self.primary_node_configured?
      Gitlab::Geo.primary_node.present?
    end

    def self.secondary_with_primary?
      self.secondary? && self.primary_node_configured?
    end

    def self.license_allows?
      ::License.feature_available?(:geo)
    end

    def self.primary?
      self.cache_value(:geo_node_primary) { self.enabled? && self.current_node && self.current_node.primary? }
    end

    def self.secondary?
      self.cache_value(:geo_node_secondary) { self.enabled? && self.current_node && self.current_node.secondary? }
    end

    def self.geo_node?(host:, port:)
      GeoNode.where(host: host, port: port).exists?
    end

    def self.fdw?
      self.cache_value(:geo_fdw?) do
        ::Geo::BaseRegistry.connection.execute(
          "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '#{FDW_SCHEMA}' AND table_type = 'FOREIGN TABLE'"
        ).first.fetch('count').to_i.positive?
      end
    end

    def self.fdw_table(table_name)
      FDW_SCHEMA + ".#{table_name}"
    end

    def self.repository_sync_job
      Sidekiq::Cron::Job.find('geo_repository_sync_worker')
    end

    def self.file_download_job
      Sidekiq::Cron::Job.find('geo_file_download_dispatch_worker')
    end

    def self.configure_primary_jobs!
      self.enable_all_cron_jobs!
      SECONDARY_JOBS.each { |job| self.__send__(job).try(:disable!) } # rubocop:disable GitlabSecurity/PublicSend
    end

    def self.configure_secondary_jobs!
      self.disable_all_cron_jobs!
      SECONDARY_JOBS.each { |job| self.__send__(job).try(:enable!) } # rubocop:disable GitlabSecurity/PublicSend
    end

    def self.disable_all_geo_jobs!
      SECONDARY_JOBS.each { |job| self.__send__(job).try(:disable!) } # rubocop:disable GitlabSecurity/PublicSend
    end

    def self.disable_all_cron_jobs!
      self.cron_jobs.select(&:enabled?).each { |job| job.disable! }
    end

    def self.enable_all_cron_jobs!
      self.cron_jobs.reject(&:enabled?).each { |job| job.enable! }
    end

    def self.cron_jobs
      Sidekiq::Cron::Job.all
    end

    def self.configure_cron_jobs!
      if self.primary?
        self.configure_primary_jobs!
      elsif self.secondary?
        self.configure_secondary_jobs!
      else
        self.enable_all_cron_jobs!
        self.disable_all_geo_jobs!
      end
    end

    def self.oauth_authentication
      return false unless Gitlab::Geo.secondary?

      self.cache_value(:geo_oauth_application) do
        Gitlab::Geo.current_node.oauth_application || raise(OauthApplicationUndefinedError)
      end
    end

    def self.cache_value(key, &block)
      return yield unless RequestStore.active?

      # We need a short expire time as we can't manually expire on a secondary node
      RequestStore.fetch(key) { Rails.cache.fetch(key, expires_in: 15.seconds) { yield } }
    end

    def self.expire_cache!
      return true unless RequestStore.active?

      CACHE_KEYS.each do |key|
        Rails.cache.delete(key)
        RequestStore.delete(key)
      end

      true
    end

    def self.generate_access_keys
      # Inspired by S3
      {
        access_key: generate_random_string(20),
        secret_access_key: generate_random_string(40)
      }
    end

    def self.generate_random_string(size)
      # urlsafe_base64 may return a string of size * 4/3
      SecureRandom.urlsafe_base64(size)[0, size]
    end
  end
end
