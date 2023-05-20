# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class ImportPullRequestNotesWorker
      include ObjectImporter

      idempotent!

      def importer_class
        Importers::PullRequestNotesImporter
      end
    end
  end
end
