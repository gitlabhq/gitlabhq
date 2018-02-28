# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportDiffNoteWorker
      include ObjectImporter

      def representation_class
        Representation::DiffNote
      end

      def importer_class
        Importer::DiffNoteImporter
      end

      def counter_name
        :github_importer_imported_diff_notes
      end

      def counter_description
        'The number of imported GitHub pull request review comments'
      end
    end
  end
end
