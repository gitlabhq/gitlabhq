# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class ImportPullRequestWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def importer_class
        Importers::PullRequestImporter
      end
    end
  end
end
