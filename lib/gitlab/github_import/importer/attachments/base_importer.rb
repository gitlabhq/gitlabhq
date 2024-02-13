# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Attachments
        class BaseImporter
          include ParallelScheduling

          BATCH_SIZE = 100

          # The method that will be called for traversing through all the objects to
          # import, yielding them to the supplied block.
          def each_object_to_import
            collection.each_batch(of: BATCH_SIZE, column: ordering_column) do |batch|
              batch.each do |record|
                next if already_imported?(record)

                if has_attachments?(record)
                  Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

                  yield record
                end

                # We mark the object as imported immediately so we don't end up
                # scheduling it multiple times.
                mark_as_imported(record)
              end
            end
          end

          def representation_class
            Representation::NoteText
          end

          def importer_class
            NoteAttachmentsImporter
          end

          private

          def collection
            raise Gitlab::GithubImport::Exceptions::NotImplementedError, '#collection'
          end

          def ordering_column
            :id
          end

          def object_representation(object)
            representation_class.from_db_record(object)
          end

          def has_attachments?(object)
            object_representation(object).has_attachments?
          end
        end
      end
    end
  end
end
