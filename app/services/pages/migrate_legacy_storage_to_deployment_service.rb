# frozen_string_literal: true

module Pages
  class MigrateLegacyStorageToDeploymentService
    ExclusiveLeaseTakenError = Class.new(StandardError)
    FailedToCreateArchiveError = Class.new(StandardError)

    include ::Pages::LegacyStorageLease

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      migrated = try_obtain_lease do
        execute_unsafe

        true
      end

      raise ExclusiveLeaseTakenError, "Can't migrate pages for project #{project.id}: exclusive lease taken" unless migrated
    end

    private

    def execute_unsafe
      archive_path, entries_count = ::Pages::ZipDirectoryService.new(project.pages_path).execute

      deployment = nil
      File.open(archive_path) do |file|
        deployment = project.pages_deployments.create!(
          file: file,
          file_count: entries_count,
          file_sha256: Digest::SHA256.file(archive_path).hexdigest
        )
      end

      project.set_first_pages_deployment!(deployment)
    rescue ::Pages::ZipDirectoryService::InvalidArchiveError => e
      if !project.pages_metadatum&.reload&.pages_deployment &&
         Feature.enabled?(:pages_migration_mark_as_not_deployed, project)
        project.mark_pages_as_not_deployed
      end

      raise FailedToCreateArchiveError, e
    ensure
      FileUtils.rm_f(archive_path) if archive_path
    end
  end
end
