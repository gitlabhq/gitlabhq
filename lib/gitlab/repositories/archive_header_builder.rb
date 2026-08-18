# frozen_string_literal: true

module Gitlab
  module Repositories
    # Builds HTTP headers for repository archive responses.
    # Used by both the API and web controller to ensure consistent
    # Content-Type and Content-Disposition headers for HEAD and GET requests.
    class ArchiveHeaderBuilder
      def initialize(repository, ref:, format:, append_sha:, path: nil, ref_type: nil, storage_path: '')
        @repository = repository
        @ref = ref
        @format = (format || 'tar.gz').downcase
        @append_sha = append_sha
        @path = path
        @ref_type = ref_type
        # Defaults to an empty storage path (header generation does not need it).
        # Pass the real downloads path when the metadata is also used to send the
        # archive, so the ETag and the archive body share one resolved commit.
        @storage_path = storage_path
      end

      def metadata
        @metadata ||= repository.archive_metadata(
          ref,
          storage_path,
          format,
          append_sha: append_sha,
          path: path,
          ref_type: ref_type
        )
      end

      def filename
        validate_metadata!

        "#{metadata['ArchivePrefix']}.#{format}"
      end

      # Returns the MIME type for the archive format.
      # Aligned with Workhorse behavior (workhorse/internal/git/archive.go):
      # - ZIP files get 'application/zip'
      # - All other formats get 'application/octet-stream'
      def content_type
        format == 'zip' ? 'application/zip' : 'application/octet-stream'
      end

      def content_disposition
        ActionDispatch::Http::ContentDisposition.format(
          disposition: 'attachment',
          filename: filename
        )
      end

      private

      attr_reader :repository, :ref, :format, :append_sha, :path, :ref_type, :storage_path

      def validate_metadata!
        raise Gitlab::Workhorse::ArchiveNotFoundError, "Repository or ref not found" if metadata.empty?
      end
    end
  end
end
