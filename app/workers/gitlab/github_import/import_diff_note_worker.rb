# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportDiffNoteWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::DiffNote
      end

      def importer_class
        Importer::DiffNoteImporter
      end

      def object_type
        :diff_note
      end
    end
  end
end
