# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class LfsObjectsImporter
        include ParallelScheduling

        def importer_class
          LfsObjectImporter
        end

        def representation_class
          Representation::LfsObject
        end

        def sidekiq_worker_class
          ImportLfsObjectWorker
        end

        def object_type
          :lfs_object
        end

        def collection_method
          :lfs_objects
        end

        def each_object_to_import
          download_service = Projects::LfsPointers::LfsObjectDownloadListService.new(project)

          download_service.each_list_item do |object|
            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

            yield object
          end
        rescue StandardError => e
          Gitlab::Import::ImportFailureService.track(
            project_id: project.id,
            error_source: importer_class.name,
            exception: e
          )
        end
      end
    end
  end
end
