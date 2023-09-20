# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def importer_class
        Importers::IssueImporter
      end
    end
  end
end
