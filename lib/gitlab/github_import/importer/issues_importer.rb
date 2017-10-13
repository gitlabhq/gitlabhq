# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssuesImporter
        include ParallelScheduling

        def importer_class
          IssueAndLabelLinksImporter
        end

        def representation_class
          Representation::Issue
        end

        def sidekiq_worker_class
          ImportIssueWorker
        end

        def collection_method
          :issues
        end

        def id_for_already_imported_cache(issue)
          issue.number
        end

        def collection_options
          { state: 'all', sort: 'created', direction: 'asc' }
        end
      end
    end
  end
end
