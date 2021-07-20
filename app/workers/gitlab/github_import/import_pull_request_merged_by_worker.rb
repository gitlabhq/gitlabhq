# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportPullRequestMergedByWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      tags :exclude_from_kubernetes

      def representation_class
        Gitlab::GithubImport::Representation::PullRequest
      end

      def importer_class
        Importer::PullRequestMergedByImporter
      end

      def object_type
        :pull_request_merged_by
      end
    end
  end
end
