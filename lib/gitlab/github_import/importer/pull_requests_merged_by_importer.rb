# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestsMergedByImporter
        include ParallelScheduling

        def importer_class
          PullRequestMergedByImporter
        end

        def representation_class
          Gitlab::GithubImport::Representation::PullRequest
        end

        def sidekiq_worker_class
          ImportPullRequestMergedByWorker
        end

        def collection_method
          :pull_requests_merged_by
        end

        def id_for_already_imported_cache(pr)
          pr.number
        end

        def each_object_to_import
          project.merge_requests.with_state(:merged).find_each do |merge_request|
            pull_request = client.pull_request(project.import_source, merge_request.iid)
            yield(pull_request)
          end
        end
      end
    end
  end
end
