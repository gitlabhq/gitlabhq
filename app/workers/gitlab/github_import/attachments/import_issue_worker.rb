# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Attachments
      class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
        include ObjectImporter

        def representation_class
          Representation::NoteText
        end

        def importer_class
          Importer::NoteAttachmentsImporter
        end

        def object_type
          :issue_attachment
        end
      end
    end
  end
end
