# frozen_string_literal: true

module Gitlab
  module GithubImport
    module PullRequests
      class ImportReviewRequestWorker # rubocop:disable Scalability/IdempotentWorker
        include ObjectImporter

        worker_resource_boundary :cpu

        def representation_class
          Gitlab::GithubImport::Representation::PullRequests::ReviewRequests
        end

        def importer_class
          Importer::PullRequests::ReviewRequestImporter
        end

        def object_type
          :pull_request_review_request
        end
      end
    end
  end
end
