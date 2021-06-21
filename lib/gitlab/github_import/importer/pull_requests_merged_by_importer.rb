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

        def object_type
          :pull_request_merged_by
        end

        def id_for_already_imported_cache(merge_request)
          merge_request.id
        end

        def each_object_to_import
          project.merge_requests.with_state(:merged).find_each do |merge_request|
            next if already_imported?(merge_request)

            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

            pull_request = client.pull_request(project.import_source, merge_request.iid)
            yield(pull_request)

            mark_as_imported(merge_request)
          end
        end
      end
    end
  end
end
