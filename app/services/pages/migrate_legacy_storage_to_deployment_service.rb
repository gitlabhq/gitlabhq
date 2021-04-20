# frozen_string_literal: true

module Pages
  class MigrateLegacyStorageToDeploymentService
    ExclusiveLeaseTakenError = Class.new(StandardError)

    include BaseServiceUtility
    include ::Pages::LegacyStorageLease

    attr_reader :project

    def initialize(project, ignore_invalid_entries: false, mark_projects_as_not_deployed: false)
      @project = project
      @ignore_invalid_entries = ignore_invalid_entries
      @mark_projects_as_not_deployed = mark_projects_as_not_deployed
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
      zip_result = ::Pages::ZipDirectoryService.new(project.pages_path, ignore_invalid_entries: @ignore_invalid_entries).execute

      if zip_result[:status] == :error
        return error("Can't create zip archive: #{zip_result[:message]}")
      end

      archive_path = zip_result[:archive_path]

      unless archive_path
        return error("Archive not created. Missing public directory in #{@project.pages_path}") unless @mark_projects_as_not_deployed

        project.set_first_pages_deployment!(nil)

        return success(
          message: "Archive not created. Missing public directory in #{project.pages_path}? Marked project as not deployed")
      end

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
