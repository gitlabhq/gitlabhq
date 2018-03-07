# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportNoteWorker
      include ObjectImporter

      def representation_class
        Representation::Note
      end

      def importer_class
        Importer::NoteImporter
      end

      def counter_name
        :github_importer_imported_notes
      end

      def counter_description
        'The number of imported GitHub comments'
      end
    end
  end
end
