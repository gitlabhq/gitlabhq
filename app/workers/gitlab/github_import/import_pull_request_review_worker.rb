# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportPullRequestReviewWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      worker_resource_boundary :cpu

      def representation_class
        Gitlab::GithubImport::Representation::PullRequestReview
      end

      def importer_class
        Importer::PullRequestReviewImporter
      end

      def object_type
        :pull_request_review
      end
    end
  end
end
