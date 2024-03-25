# frozen_string_literal: true

# This module is used in:
#  - SingleEndpointDiffNotesImporter
# if enabled by Gitlab::GithubImport::Settings
#
# - SingleEndpointIssueEventsImporter
# if enabled by Gitlab::GithubImport::Settings
#
# Fetches associated objects page by page to each item of parent collection.
# Currently `associated` is note or event.
# Currently `parent` is MergeRequest or Issue record.
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

      def each_object_to_import(&block)
        each_associated_page do |parent_record, associated_page|
          associated_page.objects.each do |associated|
            each_associated(parent_record, associated, &block)
          end
        end
      end

      def id_for_already_imported_cache(associated)
        associated[:id]
      end

      def parent_collection
        raise NotImplementedError
      end

      def parent_imported_cache_key
        raise NotImplementedError
      end

      def page_counter_id(parent)
        raise NotImplementedError
      end

      private

      # Sometimes we need to add some extra info from parent
      # to associated record that is not available by default
      # in Github API response object. For example:
      # lib/gitlab/github_import/importer/single_endpoint_issue_events_importer.rb:26
      def each_associated(_parent_record, associated)
        associated = associated.to_h

        return if already_imported?(associated)

        Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

        yield(associated)

        mark_as_imported(associated)
      end

      def each_associated_page(&block)
        parent_collection.each_batch(of: BATCH_SIZE, column: :iid) do |batch|
          process_batch(batch, &block)
        end
      end

      def process_batch(batch)
        batch.each do |parent_record|
          # The page counter needs to be scoped by parent_record to avoid skipping
          # pages of notes from already imported parent_record.
          page_counter = Gitlab::Import::PageCounter.new(project, page_counter_id(parent_record))
          repo = project.import_source
          options = collection_options.merge(page: page_counter.current)

          client.each_page(collection_method, repo, parent_record.iid, options) do |page|
            next unless page_counter.set(page.number)

            yield parent_record, page
          end

          after_batch_processed(parent_record)
          mark_parent_imported(parent_record)
        end
      end

      def mark_parent_imported(parent)
        Gitlab::Cache::Import::Caching.set_add(
          parent_imported_cache_key,
          parent.iid
        )
      end

      def after_batch_processed(_parent); end

      def already_imported_parents
        Gitlab::Cache::Import::Caching.values_from_set(parent_imported_cache_key)
      end
    end
  end
end
