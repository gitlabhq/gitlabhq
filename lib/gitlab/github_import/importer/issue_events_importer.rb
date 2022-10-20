# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueEventsImporter
        include ParallelScheduling

        def importer_class
          IssueEventImporter
        end

        def representation_class
          Representation::IssueEvent
        end

        def sidekiq_worker_class
          ImportIssueEventWorker
        end

        def object_type
          :issue_event
        end

        def collection_method
          :repository_issue_events
        end

        def id_for_already_imported_cache(event)
          event[:id]
        end
      end
    end
  end
end
