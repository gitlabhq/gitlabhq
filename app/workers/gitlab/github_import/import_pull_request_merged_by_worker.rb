# frozen_string_literal: true

# TODO: remove in 16.1 milestone
# https://gitlab.com/gitlab-org/gitlab/-/issues/409706
module Gitlab
  module GithubImport
    class ImportPullRequestMergedByWorker # rubocop:disable Scalability/IdempotentWorker
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
