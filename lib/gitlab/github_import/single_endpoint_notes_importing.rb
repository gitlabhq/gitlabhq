# frozen_string_literal: true

# This module is used in:
#  - SingleEndpointDiffNotesImporter
#  - SingleEndpointIssueNotesImporter
#  - SingleEndpointMergeRequestNotesImporter
#
# `github_importer_single_endpoint_notes_import`
# feature flag is on.
#
# It fetches 1 PR's associated objects at a time using `issue_comments` or
# `pull_request_comments` endpoint, which is slower than `NotesImporter`
# but it makes sure all notes are imported, as it can sometimes not be
# the case for `NotesImporter`, because `issues_comments` endpoint
# it uses can be limited by GitHub API to not return all available pages.
module Gitlab
  module GithubImport
    module SingleEndpointNotesImporting
      BATCH_SIZE = 100

      def each_object_to_import
        each_notes_page do |page|
          page.objects.each do |note|
            next if already_imported?(note)

            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

            yield(note)

            mark_as_imported(note)
          end
        end
      end

      def id_for_already_imported_cache(note)
        note.id
      end

      private

      def each_notes_page
        noteables.each_batch(of: BATCH_SIZE, column: :iid) do |batch|
          batch.each do |noteable|
            # The page counter needs to be scoped by noteable to avoid skipping
            # pages of notes from already imported noteables.
            page_counter = PageCounter.new(project, page_counter_id(noteable))
            repo = project.import_source
            options = collection_options.merge(page: page_counter.current)

            client.each_page(collection_method, repo, noteable.iid, options) do |page|
              next unless page_counter.set(page.number)

              yield page
            end

            mark_notes_imported(noteable)
          end
        end
      end

      def mark_notes_imported(noteable)
        Gitlab::Cache::Import::Caching.set_add(
          notes_imported_cache_key,
          noteable.iid
        )
      end

      def already_imported_noteables
        Gitlab::Cache::Import::Caching.values_from_set(notes_imported_cache_key)
      end

      def noteables
        NotImplementedError
      end

      def notes_imported_cache_key
        NotImplementedError
      end

      def page_counter_id(noteable)
        NotImplementedError
      end
    end
  end
end
