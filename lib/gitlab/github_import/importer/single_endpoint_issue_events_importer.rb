# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class SingleEndpointIssueEventsImporter
        include ParallelScheduling
        include SingleEndpointNotesImporting

        PROCESSED_PAGE_CACHE_KEY = 'issues/%{issue_iid}/%{collection}'
        BATCH_SIZE = 100

        def initialize(project, client, parallel: true)
          @project = project
          @client = client
          @parallel = parallel
          @already_imported_cache_key = ALREADY_IMPORTED_CACHE_KEY %
            { project: project.id, collection: collection_method }
        end

        def each_associated(parent_record, associated)
          return if already_imported?(associated)

          Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

          associated.issue_db_id = parent_record.id
          yield(associated)

          mark_as_imported(associated)
        end

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
          :issue_timeline
        end

        def parent_collection
          project.issues.where.not(iid: already_imported_parents).select(:id, :iid) # rubocop: disable CodeReuse/ActiveRecord
        end

        def parent_imported_cache_key
          "github-importer/issues/#{collection_method}/already-imported/#{project.id}"
        end

        def page_counter_id(issue)
          PROCESSED_PAGE_CACHE_KEY % { issue_iid: issue.iid, collection: collection_method }
        end

        def id_for_already_imported_cache(event)
          event.id
        end

        def collection_options
          { state: 'all', sort: 'created', direction: 'asc' }
        end
      end
    end
  end
end
