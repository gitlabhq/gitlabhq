# frozen_string_literal: true

module Gitlab
  module GithubImport
    module PullRequests
      class ImportMergedByWorker # rubocop:disable Scalability/IdempotentWorker
        include ObjectImporter

        worker_resource_boundary :cpu

        def representation_class
          Gitlab::GithubImport::Representation::PullRequest
        end

        def importer_class
          Importer::PullRequests::MergedByImporter
        end

        def object_type
          :pull_request_merged_by
        end
      end
    end
  end
end
