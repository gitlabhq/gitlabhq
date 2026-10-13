# frozen_string_literal: true

module Import
  module Github
    # Reads the GitHub App settings used by continuous imports.
    #
    # Secrets remain outside persisted project and import records. File-backed
    # private keys fail closed without exposing paths or operating-system errors.
    class Configuration
      APP_ID_ENV = 'GITLAB_IMPORT_SYNC_GITHUB_APP_ID'
      PRIVATE_KEY_ENV = 'GITLAB_IMPORT_SYNC_GITHUB_APP_PRIVATE_KEY'
      PRIVATE_KEY_FILE_ENV = 'GITLAB_IMPORT_SYNC_GITHUB_APP_PRIVATE_KEY_FILE'
      WEBHOOK_SECRET_ENV = 'GITLAB_IMPORT_SYNC_GITHUB_WEBHOOK_SECRET'

      def app_id
        ENV[APP_ID_ENV].presence
      end

      # Returns the inline private key or reads it from the configured local file.
      #
      # @return [String, nil] key bytes, or nil when no readable key is available
      # @note File I/O occurs only for the file-backed form. Missing, unreadable,
      #   or concurrently removed files are sanitized to nil for the JWT boundary.
      def private_key
        ENV[PRIVATE_KEY_ENV].presence || private_key_from_file
      end

      def webhook_secret
        ENV[WEBHOOK_SECRET_ENV].presence
      end

      # Reports whether the required App settings and a usable key source are present.
      #
      # @return [Boolean] true when the App ID, a usable private key source, and the webhook secret are all present
      def configured?
        [app_id, private_key_source?, webhook_secret].all?(&:present?)
      end

      def inspect
        "#<#{self.class.name}>"
      end

      private

      # Prefers an inline key and otherwise validates the file source without reading it.
      #
      # @return [Boolean] whether a regular, readable key source currently exists
      # @note File metadata checks perform local I/O and sanitize invalid paths.
      def private_key_source?
        ENV[PRIVATE_KEY_ENV].present? || readable_private_key_file?
      end

      # Reads key bytes from the configured file while containing local I/O failures.
      #
      # @return [String, nil] file contents, or nil for absent and unreadable files
      # @note The value is not cached or persisted. A file changed between the
      #   readiness check and this read fails as an ordinary configuration error.
      def private_key_from_file
        path = ENV[PRIVATE_KEY_FILE_ENV].presence
        return unless path

        File.binread(path)
      rescue SystemCallError, IOError, ArgumentError
        nil
      end

      # Checks configured path metadata without opening the candidate.
      #
      # @return [Boolean] true only for a regular file readable by this process
      # @note Missing, malformed, and inaccessible paths return false without
      #   exposing provider configuration or operating-system details.
      def readable_private_key_file?
        path = ENV[PRIVATE_KEY_FILE_ENV].presence
        return false unless path

        File.file?(path) && File.readable?(path)
      rescue SystemCallError, ArgumentError
        false
      end
    end
  end
end
