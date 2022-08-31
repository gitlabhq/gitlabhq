# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportReleaseAttachmentsWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::ReleaseAttachments
      end

      def importer_class
        Importer::ReleaseAttachmentsImporter
      end

      def object_type
        :release_attachment
      end
    end
  end
end
