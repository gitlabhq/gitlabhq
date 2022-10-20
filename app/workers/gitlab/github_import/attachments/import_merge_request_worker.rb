# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Attachments
      class ImportMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
        include ObjectImporter

        def representation_class
          Representation::NoteText
        end

        def importer_class
          Importer::NoteAttachmentsImporter
        end

        def object_type
          :merge_request_attachment
        end
      end
    end
  end
end
