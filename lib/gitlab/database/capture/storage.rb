# frozen_string_literal: true

module Gitlab
  module Database
    module Capture
      class Storage
        CONNECTORS = {
          'Gcs' => StorageConnectors::Gcs
        }.freeze

        def self.upload(...)
          new.upload(...)
        end

        def upload(filename, data)
          log("Upload request for database capture", filename)
          start_monotonic_time = ::Gitlab::Metrics::System.monotonic_time

          result = connector.upload(filename, data)

          duration_s = ::Gitlab::Metrics::System.monotonic_time - start_monotonic_time
          log("Database capture upload completed", filename, duration_s)

          result
        rescue StandardError => error
          log("Database capture upload failed: #{error}", filename)

          raise
        end

        private

        # Fetches the configured provider or uses +StorageConnectors::Local+ as fallback connector.
        def connector
          CONNECTORS.fetch(connector_provider, StorageConnectors::Local).new(connector_settings)
        end

        def connector_provider
          connector_settings.try(:provider)
        end

        def connector_settings
          Settings.database_traffic_capture.config.storage.connector
        end

        def log(message, filename, duration = nil)
          info = { message: message, connector: connector_provider, filename: filename, duration: duration }

          Gitlab::AppLogger.info(info.compact)
        end
      end
    end
  end
end
