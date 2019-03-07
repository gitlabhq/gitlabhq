# frozen_string_literal: true

module Gitlab
  module DiscussionsDiff
    class FileCollection
      include Gitlab::Utils::StrongMemoize

      def initialize(collection)
        @collection = collection
      end

      # Returns a Gitlab::Diff::File with the given ID (`unique_identifier` in
      # Gitlab::Diff::File).
      def find_by_id(id)
        diff_files_indexed_by_id[id]
      end

      # Writes cache and preloads highlighted diff lines for
      # object IDs, in @collection.
      #
      # highlightable_ids - Diff file `Array` responding to ID. The ID will be used
      # to generate the cache key.
      #
      # - Highlight cache is written just for uncached diff files
      # - The cache content is not updated (there's no need to do so)
      def load_highlight(highlightable_ids)
        preload_highlighted_lines(highlightable_ids)
      end

      private

      def preload_highlighted_lines(ids)
        cached_content = read_cache(ids)

        uncached_ids = ids.select.each_with_index { |_, i| cached_content[i].nil? }
        mapping = highlighted_lines_by_ids(uncached_ids)

        HighlightCache.write_multiple(mapping)

        diffs = diff_files_indexed_by_id.values_at(*ids)

        diffs.zip(cached_content).each do |diff, cached_lines|
          next unless diff && cached_lines

          diff.highlighted_diff_lines = cached_lines
        end
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
        strong_memoize(:diff_files) do
          @collection.map(&:raw_diff_file)
        end
      end

      # Processes the diff lines highlighting for diff files matching the given
      # IDs.
      #
      # Returns a Hash with { id => [Array of Gitlab::Diff::line], ...]
      def highlighted_lines_by_ids(ids)
        diff_files_indexed_by_id.slice(*ids).each_with_object({}) do |(id, file), hash|
          hash[id] = file.highlighted_diff_lines.map(&:to_hash)
        end
      end
    end
  end
end
