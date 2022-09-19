# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ReleasesAttachmentsImporter
        include ParallelScheduling

        BATCH_SIZE = 100

        # The method that will be called for traversing through all the objects to
        # import, yielding them to the supplied block.
        def each_object_to_import
          project.releases.select(:id, :description).each_batch(of: BATCH_SIZE, column: :id) do |batch|
            batch.each do |release|
              next if already_imported?(release)

              Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

              yield release

              # We mark the object as imported immediately so we don't end up
              # scheduling it multiple times.
              mark_as_imported(release)
            end
          end
        end

        def representation_class
          Representation::ReleaseAttachments
        end

        def importer_class
          ReleaseAttachmentsImporter
        end

        def sidekiq_worker_class
          ImportReleaseAttachmentsWorker
        end

        def collection_method
          :release_attachments
        end

        def object_type
          :release_attachment
        end

        def id_for_already_imported_cache(release)
          release.id
        end

        def object_representation(object)
          representation_class.from_db_record(object)
        end
      end
    end
  end
end
