# frozen_string_literal: true

module Import
  module PlaceholderReferences
    class BaseService
      include Services::ReturnServiceResponses

      def initialize(import_source:, import_uid:)
        @import_source = import_source
        @import_uid = import_uid
      end

      private

      attr_reader :import_source, :import_uid

      def store
        @store ||= PlaceholderReferences::Store.new(import_source: import_source, import_uid: import_uid)
      end

      def logger
        Framework::Logger
      end

      def log_info(...)
        logger.info(logger_params(...))
      end

      def log_error(...)
        logger.error(logger_params(...))
      end

      def logger_params(message:, **params)
        params.merge(
          message: message,
          import_source: import_source,
          import_uid: import_uid
        )
      end
    end
  end
end
