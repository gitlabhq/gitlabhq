# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class SingleEndpointIssueEventsImporter
        include ParallelScheduling
        include SingleEndpointNotesImporting

        PROCESSED_PAGE_CACHE_KEY = 'issues/%{issuable_iid}/%{collection}'
        BATCH_SIZE = 100

        def initialize(project, client, parallel: true)
          @project = project
          @client = client
          @parallel = parallel
          @already_imported_cache_key = ALREADY_IMPORTED_CACHE_KEY %
            { project: project.id, collection: collection_method }
          @job_waiter_cache_key = JOB_WAITER_CACHE_KEY %
            { project: project.id, collection: collection_method }
          @job_waiter_remaining_cache_key = JOB_WAITER_REMAINING_CACHE_KEY %
            { project: project.id, collection: collection_method }
        end

        # In single endpoint there is no issue info to which associated related
        # To make it possible to identify issue in separated worker we need to patch
        # Sawyer instances here with issue number
        def each_associated(parent_record, associated)
          associated = associated.to_h

          compose_associated_id!(parent_record, associated)

          return if already_imported?(associated) || importer_class::SUPPORTED_EVENTS.exclude?(associated[:event])

          cache_event(parent_record, associated)

          increment_object_counter(associated[:event])

          pull_request = parent_record.is_a? MergeRequest
          associated[:issue] = { number: parent_record.iid, pull_request: pull_request }
          yield(associated)

          mark_as_imported(associated)
        end

        # In Github Issues and MergeRequests uses the same API to get their events.
        # Even more - they have commonly uniq iid
        def each_associated_page(&block)
          issues_collection.each_batch(of: BATCH_SIZE, column: :iid) { |batch| process_batch(batch, &block) }
          merge_requests_collection.each_batch(of: BATCH_SIZE, column: :iid) { |batch| process_batch(batch, &block) }
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

        def increment_object_counter(event_name)
          counter_type = importer_class::EVENT_COUNTER_MAP[event_name] || object_type
          Gitlab::GithubImport::ObjectCounter.increment(project, counter_type, :fetched)
        end

        def collection_method
          :issue_timeline
        end

        def issues_collection
          project.issues.where.not(iid: already_imported_parents).select(:id, :iid) # rubocop: disable CodeReuse/ActiveRecord
        end

        def merge_requests_collection
          project.merge_requests.where.not(iid: already_imported_parents).select(:id, :iid) # rubocop: disable CodeReuse/ActiveRecord
        end

        def parent_imported_cache_key
          "github-importer/issues/#{collection_method}/already-imported/#{project.id}"
        end

        def page_counter_id(issuable)
          PROCESSED_PAGE_CACHE_KEY % { issuable_iid: issuable.iid, collection: collection_method }
        end

        def id_for_already_imported_cache(event)
          event[:id]
        end

        def collection_options
          { state: 'all', sort: 'created', direction: 'asc' }
        end

        # Cross-referenced events on Github doesn't have id.
        def compose_associated_id!(issuable, event)
          return if event[:event] != 'cross-referenced'

          event[:id] = "cross-reference##{issuable.iid}-in-#{event.dig(:source, :issue, :id)}"
        end

        def import_settings
          @import_settings ||= Gitlab::GithubImport::Settings.new(project)
        end

        def after_batch_processed(parent)
          events = events_cache.events(parent)

          return if events.empty?

          hash = Representation::ReplayEvent.new(issuable_type: parent.class.name.to_s, issuable_iid: parent.iid)
            .to_hash.deep_stringify_keys
          ReplayEventsWorker.perform_async(project.id, hash, job_waiter.key.to_s)
          job_waiter.jobs_remaining = Gitlab::Cache::Import::Caching.increment(job_waiter_remaining_cache_key)
        end

        def cache_event(parent_record, associated)
          return if Importer::ReplayEventsImporter::SUPPORTED_EVENTS.exclude?(associated[:event])

          representation = representation_class.from_api_response(associated)

          events_cache.add(parent_record, representation)
        end

        def events_cache
          @events_cache ||= EventsCache.new(project)
        end
      end
    end
  end
end
