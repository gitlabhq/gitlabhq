# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class ImportPullRequestNoteWorker # rubocop:disable Scalability/IdempotentWorker -- The worker should not run multiple times to avoid creating multiple import
      include ObjectImporter

      def importer_class
        Importers::PullRequestNoteImporter
      end
    end
  end
end
