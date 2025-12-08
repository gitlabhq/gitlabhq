# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class LfsObjectImporter
        attr_reader :lfs_object, :project

        RETRY_DELAY = 120

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
          result = Projects::LfsPointers::LfsDownloadService.new(project, lfs_download_object).execute

          if result[:status] == :error && result[:message]&.include?('Received error code 429')
            raise Gitlab::GithubImport::RateLimitError.new('Rate Limit exceeded', RETRY_DELAY)
          end

          result
        end
      end
    end
  end
end
