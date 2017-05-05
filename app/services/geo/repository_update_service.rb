module Geo
  class RepositoryUpdateService
    attr_reader :project, :clone_url

    LEASE_TIMEOUT = 1.hour.freeze
    LEASE_KEY_PREFIX = 'geo_repository_fetch'.freeze

    def initialize(project, clone_url, logger = nil)
      @project = project
      @clone_url = clone_url
      @logger = logger
    end

    def execute
      try_obtain_lease do
        project.create_repository unless project.repository_exists?
        project.repository.after_create if project.empty_repo?
        project.repository.fetch_geo_mirror(clone_url)
        project.repository.expire_all_method_caches
        project.repository.expire_branch_cache
        project.repository.expire_content_cache
      end
    rescue Gitlab::Shell::Error => e
      logger.error "Error fetching repository for project #{project.path_with_namespace}: #{e}"
    end

    private

    def try_obtain_lease
      log('Trying to obtain lease to sync repository')

      repository_lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain
      unless repository_lease.present?
        log('Could not obtain lease to sync repository')

        return
      end

      begin
        yield
      ensure
        if repository_lease.present?
          log('Releasing leases to sync repository')
          Gitlab::ExclusiveLease.cancel(lease_key, repository_lease)
        end
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{project.id}"
    end

    def log(message)
      logger.info("#{self.class.name}: #{message} for project #{project.path_with_namespace} (#{project.id})")
    end

    def logger
      @logger || Rails.logger
    end
  end
end
