# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportLfsObjectWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::LfsObject
      end

      def importer_class
        Importer::LfsObjectImporter
      end

      def counter_name
        :github_importer_imported_lfs_objects
      end

      def counter_description
        'The number of imported GitHub Lfs Objects'
      end
    end
  end
end
