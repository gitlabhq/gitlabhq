# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportPullRequestWorker
      include ObjectImporter

      def representation_class
        Representation::PullRequest
      end

      def importer_class
        Importer::PullRequestImporter
      end

      def counter_name
        :github_importer_imported_pull_requests
      end

      def counter_description
        'The number of imported GitHub pull requests'
      end
    end
  end
end
