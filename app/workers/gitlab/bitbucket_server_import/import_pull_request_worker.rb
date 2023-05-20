# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class ImportPullRequestWorker
      include ObjectImporter

      idempotent!

      def importer_class
        Importers::PullRequestImporter
      end
    end
  end
end
