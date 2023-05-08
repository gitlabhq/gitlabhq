# frozen_string_literal: true

module Gitlab
  module GithubImport
    module PullRequests
      class ImportReviewWorker # rubocop:disable Scalability/IdempotentWorker
        include ObjectImporter

        worker_resource_boundary :cpu

        def representation_class
          Gitlab::GithubImport::Representation::PullRequestReview
        end

        def importer_class
          Importer::PullRequests::ReviewImporter
        end

        def object_type
          :pull_request_review
        end
      end
    end
  end
end
