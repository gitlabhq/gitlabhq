# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class ImportLfsObjectWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def importer_class
        Importers::LfsObjectImporter
      end
    end
  end
end
