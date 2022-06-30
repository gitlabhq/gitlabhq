# frozen_string_literal: true

# This importer is used when `github_importer_single_endpoint_notes_import`
# feature flag is on and replaces `DiffNotesImporter`.
#
# It fetches 1 PR's diff notes at a time using `pull_request_comments` endpoint, which is
# slower than `NotesImporter` but it makes sure all notes are imported,
# as it can sometimes not be the case for `NotesImporter`, because
# `issues_comments` endpoint it uses can be limited by GitHub API
# to not return all available pages.
module Gitlab
  module GithubImport
    module Importer
      class SingleEndpointDiffNotesImporter
        include ParallelScheduling
        include SingleEndpointNotesImporting

        def importer_class
          DiffNoteImporter
        end

        def representation_class
          Representation::DiffNote
        end

        def sidekiq_worker_class
          ImportDiffNoteWorker
        end

        def object_type
          :diff_note
        end

        def collection_method
          :pull_request_comments
        end

        private

        def parent_collection
          project.merge_requests.where.not(iid: already_imported_parents) # rubocop: disable CodeReuse/ActiveRecord
        end

        def page_counter_id(merge_request)
          "merge_request/#{merge_request.id}/#{collection_method}"
        end

        def parent_imported_cache_key
          "github-importer/merge_request/diff_notes/already-imported/#{project.id}"
        end
      end
    end
  end
end
