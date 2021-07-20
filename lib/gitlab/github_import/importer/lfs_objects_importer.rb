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
          lfs_objects = Projects::LfsPointers::LfsObjectDownloadListService.new(project).execute

          lfs_objects.each do |object|
            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

            yield object
          end
        rescue StandardError => e
          error(project.id, e)
        end
      end
    end
  end
end
