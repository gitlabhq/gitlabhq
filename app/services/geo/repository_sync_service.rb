module Geo
  class RepositorySyncService
    attr_reader :project_id

    LEASE_TIMEOUT    = 8.hours.freeze
    LEASE_KEY_PREFIX = 'repository_sync_service'.freeze

    def initialize(project_id)
      @project_id = project_id
    end

    def execute
      try_obtain_lease do
        log('Started repository sync')
        sync_project_repository
        sync_wiki_repository
        log('Finished repository sync')
      end
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("#{self.class.name}: Couldn't find project with ID=#{project_id}, skipping syncing")
    end

    private

    def project
      @project ||= Project.find(project_id)
    end

    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
    end

    def sync_project_repository
      return unless sync_repository?

      started_at, finished_at = fetch_project_repository
      update_registry(:repository, started_at, finished_at)
      expire_repository_caches
    end

    def sync_repository?
      registry.resync_repository? ||
        registry.last_repository_successful_sync_at.nil? ||
        registry.last_repository_synced_at.nil?
    end

    def sync_wiki_repository
      return unless sync_wiki?

      started_at, finished_at = fetch_wiki_repository
      update_registry(:wiki, started_at, finished_at)
    end

    def sync_wiki?
      registry.resync_wiki? ||
        registry.last_wiki_successful_sync_at.nil? ||
        registry.last_wiki_synced_at.nil?
    end

    def fetch_project_repository
      return unless sync_repository?

      log('Fetching project repository')
      started_at  = DateTime.now
      finished_at = nil

      begin
        project.ensure_repository
        project.repository.fetch_geo_mirror(ssh_url_to_repo)

        finished_at = DateTime.now
      rescue Gitlab::Shell::Error => e
        Rails.logger.error("#{self.class.name}: Error syncing repository for project #{project.path_with_namespace}: #{e}")
      rescue Gitlab::Git::Repository::NoRepository => e
        Rails.logger.error("#{self.class.name}: Error invalid repository for project #{project.path_with_namespace}: #{e}")
        log('Expiring caches')
        project.repository.after_create
      end

      [started_at, finished_at]
    end

    def fetch_wiki_repository
      return unless sync_wiki?

      log('Fetching wiki repository')
      started_at  = DateTime.now
      finished_at = nil

      begin
        project.wiki.ensure_repository
        project.wiki.repository.fetch_geo_mirror(ssh_url_to_wiki)

        finished_at = DateTime.now
      rescue Gitlab::Git::Repository::NoRepository, Gitlab::Shell::Error, ProjectWiki::CouldNotCreateWikiError => e
        Rails.logger.error("#{self.class.name}: Error syncing wiki repository for project #{project.path_with_namespace}: #{e}")
      end

      [started_at, finished_at]
    end

    def expire_repository_caches
      log('Expiring caches')
      project.repository.after_sync
    end

    def try_obtain_lease
      log('Trying to obtain lease to sync repository')
      repository_lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

      unless repository_lease
        log('Could not obtain lease to sync repository')
        return
      end

      yield

      # We should release the lease for a repository, only if we have obtained
      # it. If something went wrong when syncing the repository, we should wait
      # for the lease timeout to try again.
      log('Releasing leases to sync repository')
      Gitlab::ExclusiveLease.cancel(lease_key, repository_lease)
    end

    def update_registry(type, started_at, finished_at)
      log("Updating #{type} sync information")
      registry.public_send("last_#{type}_synced_at=", started_at)

      if finished_at
        registry.public_send("last_#{type}_successful_sync_at=", finished_at)
        registry.public_send("resync_#{type}=", false)
      end

      registry.save
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{project.id}"
    end

    def primary_ssh_path_prefix
      Gitlab::Geo.primary_node.clone_url_prefix
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.git"
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.wiki.git"
    end

    def log(message)
      Rails.logger.info("#{self.class.name}: #{message} for project #{project.path_with_namespace} (#{project.id})")
    end
  end
end
