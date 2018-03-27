# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class NotesImporter
        include ParallelScheduling

        def importer_class
          NoteImporter
        end

        def representation_class
          Representation::Note
        end

        def sidekiq_worker_class
          ImportNoteWorker
        end

        def collection_method
          :issues_comments
        end

        def id_for_already_imported_cache(note)
          note.id
        end
      end
    end
  end
end
