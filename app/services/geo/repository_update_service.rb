module Geo
  class RepositoryUpdateService
    include Gitlab::Geo::ProjectLogHelpers

    attr_reader :project, :clone_url, :logger

    LEASE_TIMEOUT = 1.hour.freeze
    LEASE_KEY_PREFIX = 'geo_repository_fetch'.freeze

    def initialize(project, clone_url, logger = Rails.logger)
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
      log_error('Error fetching repository for project', e)
    rescue Gitlab::Git::Repository::NoRepository => e
      log_error('Error invalid repository', e)
      log_info('Invalidating cache for project')
      project.repository.after_create
    end

    private

    def try_obtain_lease
      log_info('Trying to obtain lease to sync repository')

      repository_lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain
      unless repository_lease.present?
        log_info('Could not obtain lease to sync repository')

        return
      end

      begin
        yield
      ensure
        log_info('Releasing leases to sync repository')
        Gitlab::ExclusiveLease.cancel(lease_key, repository_lease)
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{project.id}"
    end
  end
end
