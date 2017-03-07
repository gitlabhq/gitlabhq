module Geo
  class RepositoryBackfillService
    attr_reader :project_id, :backfill_lease

    LEASE_TIMEOUT    = 8.hours.freeze
    LEASE_KEY_PREFIX = 'repository_backfill_service'.freeze

    def initialize(project_id, backfill_lease)
      @project_id = project_id
      @backfill_lease = backfill_lease
    end

    def execute
      try_obtain_lease do
        log('Started repository sync')

        fetch_repositories do |started_at, finished_at|
          update_registry(started_at, finished_at)
        end

        log('Finished repository sync')
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("Couldn't find project with ID=#{project_id}, skipping syncing")
    ensure
      Gitlab::ExclusiveLease.cancel(LEASE_KEY_PREFIX, backfill_lease)
    end

    private

    def project
      @project ||= Project.find(project_id)
    end

    def fetch_repositories
      started_at  = DateTime.now
      finished_at = nil

      begin
        fetch_project_repository
        fetch_wiki_repository
        expire_repository_caches

        finished_at = DateTime.now
      rescue Gitlab::Shell::Error => e
        Rails.logger.error "Error syncing repository for project #{project.path_with_namespace}: #{e}"
      end

      yield started_at, finished_at
    end

    def fetch_project_repository
      log('Fetching project repository')
      project.create_repository unless project.repository_exists?
      project.repository.fetch_geo_mirror(ssh_url_to_repo)
    end

    def fetch_wiki_repository
      # Second .wiki call returns a Gollum::Wiki, and it will always create the physical repository when not found
      if project.wiki.wiki.exist?
        log('Fetching wiki repository')
        project.wiki.repository.fetch_geo_mirror(ssh_url_to_wiki)
      end
    end

    def expire_repository_caches
      log('Expiring caches')
      project.repository.after_sync
    end

    def try_obtain_lease
      log('Trying to obtain lease to sync repository')

      repository_lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

      if repository_lease.nil?
        log('Could not obtain lease to sync repository')
        return
      end

      yield

      log('Releasing leases to sync repository')
      Gitlab::ExclusiveLease.cancel(lease_key, repository_lease)
    end

    def update_registry(started_at, finished_at)
      log('Updating registry information')
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
      registry.last_repository_synced_at = started_at
      registry.last_repository_successful_sync_at = finished_at if finished_at
      registry.save
    end

    def lease_key
      @key ||= "#{LEASE_KEY_PREFIX}:#{project.id}"
    end

    def primary_ssh_path_prefix
      Gitlab::Geo.primary_ssh_path_prefix
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.git"
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.wiki.git"
    end

    def log(message)
      Rails.logger.info "#{self.class.name}: #{message} for project #{project.path_with_namespace} (#{project.id})"
    end
  end
end
