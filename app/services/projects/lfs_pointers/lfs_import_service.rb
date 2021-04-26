# frozen_string_literal: true

# This service is responsible of managing the retrieval of the lfs objects,
# and call the service LfsDownloadService, which performs the download
# for each of the retrieved lfs objects
module Projects
  module LfsPointers
    class LfsImportService < BaseService
      def execute
        return success unless project&.lfs_enabled?

        lfs_objects_to_download = LfsObjectDownloadListService.new(project).execute

        lfs_objects_to_download.each do |lfs_download_object|
          LfsDownloadService.new(project, lfs_download_object).execute
        end

        success
      rescue StandardError => e
        error(e.message)
      end
    end
  end
end
