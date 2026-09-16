# frozen_string_literal: true

module Gitlab
  module Cleanup
    class RemoteArtifacts < RemoteObjectStorage
      extend ::Gitlab::Utils::Override

      # `row_values` returns the values in this order and the batch query plucks them in this
      # order, so a change to one cannot silently disagree with the other.
      TRACKING_COLUMNS = %i[id job_id file].freeze
      NUMERIC_TRACKING_COLUMNS = %i[id job_id].freeze
      ID_INDEX = TRACKING_COLUMNS.index(:id)

      # <sha256_prefix>/<sha256_prefix>/<sha256_hash>/<date>/<job_id>/<artifact_id>/<filename>, e.g.
      # 4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/2025_04_23/1/1/build.zip
      #
      # Anchored at both ends: an unanchored match would shift the capture groups on a prefixed
      # key, and the resulting lookup would report a tracked object as an orphan.
      FILE_PATH_REGEXP = %r{
        \A
        [0-9a-f]{2}/[0-9a-f]{2}/[0-9a-f]{64}
        /\d{4}_\d{2}_\d{2}
        /(?<job_id>\d+)
        /(?<id>\d+)
        /(?<file>[^/]+)
        \z
      }x

      def initialize(logger: nil)
        super(:artifacts, ::Ci::JobArtifact, logger: logger)
      end

      private

      # @return [Regexp] the expected file path format regexp.
      override :expected_file_path_format_regexp
      def expected_file_path_format_regexp
        FILE_PATH_REGEXP
      end

      # Resolves the whole batch with a single query. The inherited per-file implementation, and so
      # also `query_for_row_tracking_the_file`, cannot complete on buckets holding billions of
      # objects.
      #
      # @param file_paths [Array<String>] an array of remote file paths
      # @return [Array<String>] a subset of the input paths that are tracked in the DB
      override :find_tracked_paths
      def find_tracked_paths(file_paths)
        # Grouped rather than indexed: two keys can carry the same tracking values, and keeping
        # only one of them would report the other tracked object as an orphan. `row_values`
        # returns nil for a key it cannot parse, which keeps this to one match per path.
        paths_by_row = file_paths.group_by { |file_path| row_values(file_path) }
        unknown_format = paths_by_row.delete(nil) || []

        # Calling the predicate makes the base class log each unparseable key.
        unknown_format.each { |file_path| valid_file_path_format?(file_path) }

        tracked_rows = tracked_row_values(paths_by_row.keys)
        log_batch(paths_by_row, tracked_rows.to_set)

        # An unrecognized path format defaults to "tracked" so that an unknown layout is never
        # deleted.
        paths_by_row.values_at(*tracked_rows).flatten(1) + unknown_format
      end

      # @param file_path [String] a remote file path in this bucket
      # @return [Array, nil] the tracking column values that a row for this file would hold
      def row_values(file_path)
        match = expected_file_path_format_regexp.match(file_path)
        return unless match

        TRACKING_COLUMNS.map do |column|
          value = match[column]

          NUMERIC_TRACKING_COLUMNS.include?(column) ? value.to_i : value
        end
      end

      # @param rows [Array<Array>] the tracking column values to look for
      # @return [Array<Array>] the subset of `rows` that exists in the DB
      def tracked_row_values(rows)
        return [] if rows.empty?

        ids = rows.map { |row| row[ID_INDEX] } # rubocop:disable Rails/Pluck -- rows is an Array, not a relation

        # rubocop:disable CodeReuse/ActiveRecord -- this is not a reusable scope
        # Filtering on `id` alone keeps the query on the primary key. The remaining values are
        # compared in memory so that a single query resolves the whole batch.
        model_class.where(id: ids).pluck(*TRACKING_COLUMNS) & rows
        # rubocop:enable CodeReuse/ActiveRecord
      end

      # @return [void]
      def log_batch(paths_by_row, tracked_rows)
        paths_by_row.each do |row, file_paths|
          is_tracked = tracked_rows.include?(row)
          artifact_id, job_id = row

          file_paths.each do |file_path|
            log_file_tracked(
              file_path: file_path,
              is_tracked: is_tracked,
              artifact_id: artifact_id,
              job_id: job_id
            )
          end
        end

        nil
      end
    end
  end
end
