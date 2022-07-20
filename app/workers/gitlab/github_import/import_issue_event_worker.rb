# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportIssueEventWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::IssueEvent
      end

      def importer_class
        Importer::IssueEventImporter
      end

      def object_type
        :issue_event
      end
    end
  end
end
