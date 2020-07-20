# frozen_string_literal: true

module Gitlab
  module DiscussionsDiff
    class FileCollection
      include Gitlab::Utils::StrongMemoize
      include Enumerable

      def initialize(collection)
        @collection = collection
      end

      def each(&block)
        @collection.each(&block)
      end

      # Returns a Gitlab::Diff::File with the given ID (`unique_identifier` in
      # Gitlab::Diff::File).
      def find_by_id(id)
        diff_files_indexed_by_id[id]
      end

      # Writes cache and preloads highlighted diff lines for
      # highlightable object IDs, in @collection.
      #
      # - Highlight cache is written just for uncached diff files
      # - The cache content is not updated (there's no need to do so)
      def load_highlight
        ids = highlightable_collection_ids
        return if ids.empty?

        cached_content = read_cache(ids)

        uncached_ids = ids.select.each_with_index { |_, i| cached_content[i].nil? }
        mapping = highlighted_lines_by_ids(uncached_ids)

        HighlightCache.write_multiple(mapping) if mapping.any?

        diffs = diff_files_indexed_by_id.values_at(*ids)

        diffs.zip(cached_content).each do |diff, cached_lines|
          next unless diff && cached_lines

          diff.highlighted_diff_lines = cached_lines
        end
      end

      private

      def highlightable_collection_ids
        each.with_object([]) { |file, memo| memo << file.id unless file.resolved_at }
      end

      def read_cache(ids)
        HighlightCache.read_multiple(ids)
      end

      def diff_files_indexed_by_id
        strong_memoize(:diff_files_indexed_by_id) do
          diff_files.index_by(&:unique_identifier)
        end
      end

      def diff_files
        strong_memoize(:diff_files) { map(&:raw_diff_file) }
      end

      # Processes the diff lines highlighting for diff files matching the given
      # IDs.
      #
      # Returns a Hash with { id => [Array of Gitlab::Diff::line], ...]
      def highlighted_lines_by_ids(ids)
        diff_files_indexed_by_id.slice(*ids).transform_values do |file|
          file.highlighted_diff_lines.map(&:to_hash)
        end
      end
    end
  end
end
