# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class LfsObjectImporter
        include Loggable
        include ErrorTracking

        def initialize(project, lfs_attributes)
          @project = project
          @lfs_download_object = LfsDownloadObject.new(**lfs_attributes.symbolize_keys)
        end

        def execute
          log_info(import_stage: 'import_lfs_object', message: 'starting', oid: lfs_download_object.oid)

          lfs_download_object.validate!
          Projects::LfsPointers::LfsDownloadService.new(project, lfs_download_object).execute

          log_info(import_stage: 'import_lfs_object', message: 'finished', oid: lfs_download_object.oid)
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        attr_reader :lfs_download_object, :project
      end
    end
  end
end
