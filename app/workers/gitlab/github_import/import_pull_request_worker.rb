# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportPullRequestWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Gitlab::GithubImport::Representation::PullRequest
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
