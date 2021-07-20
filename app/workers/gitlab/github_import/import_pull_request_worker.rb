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

      def object_type
        :pull_request
      end
    end
  end
end
