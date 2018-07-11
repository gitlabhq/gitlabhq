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

        def execute
          Projects::LfsPointers::LfsDownloadService
            .new(project)
            .execute(lfs_object.oid, lfs_object.download_link)
        end
      end
    end
  end
end
