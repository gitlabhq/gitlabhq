# frozen_string_literal: true

module Pages
  class MigrateLegacyStorageToDeploymentService
    ExclusiveLeaseTakenError = Class.new(StandardError)

    include BaseServiceUtility
    include ::Pages::LegacyStorageLease

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      result = try_obtain_lease do
        execute_unsafe
      end

      raise ExclusiveLeaseTakenError, "Can't migrate pages for project #{project.id}: exclusive lease taken" if result.nil?

      result
    end

    private

    def execute_unsafe
      zip_result = ::Pages::ZipDirectoryService.new(project.pages_path).execute

      if zip_result[:status] == :error
        if !project.pages_metadatum&.reload&.pages_deployment &&
           Feature.enabled?(:pages_migration_mark_as_not_deployed, project)
          project.mark_pages_as_not_deployed
        end

        return error("Can't create zip archive: #{zip_result[:message]}")
      end

      archive_path = zip_result[:archive_path]

      deployment = nil
      File.open(archive_path) do |file|
        deployment = project.pages_deployments.create!(
          file: file,
          file_count: zip_result[:entries_count],
          file_sha256: Digest::SHA256.file(archive_path).hexdigest
        )
      end

      project.set_first_pages_deployment!(deployment)

      success
    ensure
      FileUtils.rm_f(archive_path) if archive_path
    end
  end
end
