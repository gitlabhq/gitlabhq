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

        def collection_method
          :lfs_objects
        end

        def each_object_to_import
          lfs_objects = Projects::LfsPointers::LfsImportService.new(project).execute

          lfs_objects.each do |object|
            yield object
          end
        rescue StandardError => e
          Gitlab::Import::Logger.error(
            message: 'The Lfs import process failed',
            error: e.message
          )
        end
      end
    end
  end
end
