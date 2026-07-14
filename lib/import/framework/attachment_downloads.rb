# frozen_string_literal: true

module Import
  module Framework
    # Provider-agnostic helpers shared by importer attachment downloaders.
    #
    # Hosts that include this module must also include
    # `BulkImports::FileDownloads::FilenameFetch` (for `ensure_filename_size`) and
    # `Gitlab::ImportExport::CommandLineUtil` (for `mkdir_p`), and must implement the
    # `attachments_temp_dir` and `filename` abstract methods defined below.
    module AttachmentDownloads
      ALLOWED_FILENAME_CHARACTERS = /[^a-zA-Z0-9\-_.]/

      private

      # The per-importer temp directory downloads land in. Host classes must override.
      def attachments_temp_dir
        raise Gitlab::AbstractMethodError
      end

      # The sanitized download filename. Host classes must override.
      def filename
        raise Gitlab::AbstractMethodError
      end

      # Parses the filename from a download URL, guards against path traversal,
      # sanitizes it and ensures it fits within the filename size limit.
      def build_filename(file_url)
        filename = URI(file_url).path.split('/').last
        filename = CGI.unescape(filename) # Decode URL-encoded characters

        # Check for path traversal before sanitization
        Gitlab::PathTraversal.check_path_traversal!(File.join(attachments_temp_dir, filename))

        filename = sanitize_filename(filename)
        ensure_filename_size(filename)
      end

      def sanitize_filename(filename)
        # Replace any character that's not alphanumeric, hyphen, underscore, or dot
        sanitized = filename.gsub(ALLOWED_FILENAME_CHARACTERS, '_')
        # Remove leading dots to prevent hidden files
        sanitized = sanitized.sub(/^\.+/, '')
        # Provide fallback if empty or only underscore characters
        sanitized.empty? || sanitized.match?(/\A_+\z/) ? 'attachment' : sanitized
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- filepath must be both memoized and mutated by add_extension_to_file_path
      def filepath
        @filepath ||= begin
          dir = File.join(attachments_temp_dir, SecureRandom.uuid)
          mkdir_p dir
          File.join(dir, filename)
        end
      end

      def add_extension_to_file_path(filename)
        @filepath = "#{filepath}#{File.extname(filename)}"
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
