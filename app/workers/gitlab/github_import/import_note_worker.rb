# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportNoteWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::Note
      end

      def importer_class
        Importer::NoteImporter
      end

      def object_type
        :note
      end
    end
  end
end
