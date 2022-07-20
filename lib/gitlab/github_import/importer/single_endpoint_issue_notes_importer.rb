# frozen_string_literal: true

# This importer is used when `github_importer_single_endpoint_notes_import`
# feature flag is on and replaces `IssuesImporter` issue notes import.
#
# It fetches 1 issue's comments at a time using `issue_comments` endpoint, which is
# slower than `NotesImporter` but it makes sure all notes are imported,
# as it can sometimes not be the case for `NotesImporter`, because
# `issues_comments` endpoint it uses can be limited by GitHub API
# to not return all available pages.
module Gitlab
  module GithubImport
    module Importer
      class SingleEndpointIssueNotesImporter
        include ParallelScheduling
        include SingleEndpointNotesImporting

        def importer_class
          NoteImporter
        end

        def representation_class
          Representation::Note
        end

        def sidekiq_worker_class
          ImportNoteWorker
        end

        def object_type
          :note
        end

        def collection_method
          :issue_comments
        end

        private

        def parent_collection
          project.issues.where.not(iid: already_imported_parents) # rubocop: disable CodeReuse/ActiveRecord
        end

        def page_counter_id(issue)
          "issue/#{issue.id}/#{collection_method}"
        end

        def parent_imported_cache_key
          "github-importer/issue/notes/already-imported/#{project.id}"
        end
      end
    end
  end
end
