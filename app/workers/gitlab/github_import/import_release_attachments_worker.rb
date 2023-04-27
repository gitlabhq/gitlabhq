# frozen_string_literal: true

# TODO: remove in 16.X milestone
# https://gitlab.com/gitlab-org/gitlab/-/issues/377059
module Gitlab
  module GithubImport
    class ImportReleaseAttachmentsWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::NoteText
      end

      def importer_class
        Importer::NoteAttachmentsImporter
      end

      def object_type
        :release_attachment
      end
    end
  end
end
