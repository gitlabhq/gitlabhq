# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class LfsObjectImporter
        include Loggable

        def initialize(project, lfs_attributes)
          @project = project
          @lfs_download_object = LfsDownloadObject.new(**lfs_attributes.symbolize_keys)
        end

        def execute
          log_info(import_stage: 'import_lfs_object', message: 'starting', oid: lfs_download_object.oid)

          Projects::LfsPointers::LfsDownloadService.new(project, lfs_download_object).execute

          log_info(import_stage: 'import_lfs_object', message: 'finished', oid: lfs_download_object.oid)
        end

        private

        attr_reader :project, :lfs_download_object
      end
    end
  end
end
