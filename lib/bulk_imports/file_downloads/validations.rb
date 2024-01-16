# frozen_string_literal: true

module BulkImports
  module FileDownloads
    module Validations
      def raise_error(message)
        raise NotImplementedError
      end

      def filepath
        raise NotImplementedError
      end

      def file_size_limit
        raise NotImplementedError
      end

      def response_headers
        raise NotImplementedError
      end

      private

      def validate_filepath
        Gitlab::PathTraversal.check_path_traversal!(filepath)
      end

      def validate_content_type
        content_type = response_headers['content-type']

        raise_error('Invalid content type') if content_type.blank? || allowed_content_types.exclude?(content_type)
      end

      def validate_symlink
        return unless Gitlab::Utils::FileInfo.linked?(filepath)

        File.delete(filepath)
        raise_error 'Invalid downloaded file'
      end

      def validate_size!(size)
        return unless file_size_limit > 0 && size.to_i > file_size_limit

        raise_error format(
          "File size %{size} exceeds limit of %{limit}",
          size: ActiveSupport::NumberHelper.number_to_human_size(size),
          limit: ActiveSupport::NumberHelper.number_to_human_size(file_size_limit)
        )
      end
    end
  end
end
