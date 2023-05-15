# frozen_string_literal: true

# TODO: remove in 16.1 milestone
# https://gitlab.com/gitlab-org/gitlab/-/issues/409706
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
