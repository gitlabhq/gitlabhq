# frozen_string_literal: true

module Gitlab
  module Cleanup
    class RemoteCiSecureFiles < RemoteObjectStorage
      extend ::Gitlab::Utils::Override

      def initialize(logger: nil)
        super(:ci_secure_files, ::Ci::SecureFile, logger: logger)
      end

      private

      # @return [Regexp] the expected file path format regexp.
      override :expected_file_path_format_regexp
      def expected_file_path_format_regexp
        %r{\A[0-9a-f]{2}/[0-9a-f]{2}/[0-9a-f]{64}/secure_files/\d+/[^/]+$}
      end

      # From SecureFileUploader:
      # def dynamic_segment
      #   Gitlab::HashedPath.new('secure_files', model.id, root_hash: model.project_id)
      # end
      #
      # @param file_path [String] a remote file path in this bucket
      # @return [ActiveRecord::Relation, nil] a relation that would match the corresponding row in the DB,
      #   if it exists, or nil if the file path doesn't match the expected format.
      override :query_for_row_tracking_the_file
      def query_for_row_tracking_the_file(file_path)
        path_parts = file_path.split('/')
        model_id = path_parts[4].to_i
        filename = path_parts[5]

        # rubocop:disable CodeReuse/ActiveRecord -- this is not a reusable scope
        model_class.where(id: model_id, file: filename.to_s)
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
