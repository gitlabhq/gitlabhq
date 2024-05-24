# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class LfsObjectImporter
        attr_reader :lfs_object, :project

        # lfs_object - An instance of `Gitlab::GithubImport::Representation::LfsObject`.
        # project - An instance of `Project`.
        def initialize(lfs_object, project, _)
          @lfs_object = lfs_object
          @project = project
        end

        def lfs_download_object
          LfsDownloadObject.new(oid: lfs_object.oid, size: lfs_object.size, link: lfs_object.link,
            headers: lfs_object.headers)
        end

        def execute
          Projects::LfsPointers::LfsDownloadService.new(project, lfs_download_object).execute
        end
      end
    end
  end
end
