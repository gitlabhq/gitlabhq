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

      def object_type
        :lfs_object
      end
    end
  end
end
