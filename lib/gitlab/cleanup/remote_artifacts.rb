# frozen_string_literal: true

module Gitlab
  module Cleanup
    class RemoteArtifacts < RemoteObjectStorage
      extend ::Gitlab::Utils::Override

      def initialize(logger: nil)
        super(:artifacts, ::Ci::JobArtifact, logger: logger)
      end

      private

      # @return [Regexp] the expected file path format regexp.
      override :expected_file_path_format_regexp
      def expected_file_path_format_regexp
        %r{[0-9a-f]{2}/[0-9a-f]{2}/[0-9a-f]{64}/\d\d\d\d_\d\d_\d\d/\d+/\d+/.+$}
      end

      # Given a remote file path like
      # 4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/2025_04_23/1/1/ci_build_artifacts.zip
      # which is composed of
      # <sha256_hash_prefix>/<sha256_hash_prefix>/<sha256_hash>/<date>/<job_id>/<artifact_id>/<filename>
      #
      # @param file_path [String] a remote file path in this bucket
      # @return [ActiveRecord::Relation, nil] a relation that would match the corresponding row in the DB,
      #   if it exists, or nil if the file path doesn't match the expected format.
      override :query_for_row_tracking_the_file
      def query_for_row_tracking_the_file(file_path)
        path_parts = file_path.split('/')
        job_id = path_parts[4].to_i
        artifact_id = path_parts[5].to_i
        filename = path_parts[6]

        # rubocop:disable CodeReuse/ActiveRecord -- this is not a reusable scope
        model_class.where(id: artifact_id, job_id: job_id, file: filename)
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
