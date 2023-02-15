# frozen_string_literal: true

module Gitlab
  module Database
    module QueueErrorHandlingConcern
      extend ActiveSupport::Concern

      MAX_LAST_ERROR_LENGTH = 10_000

      included do
        validates :last_error, length: { maximum: MAX_LAST_ERROR_LENGTH },
          if: ->(record) { record.respond_to?(:last_error) }
      end

      def handle_exception!(error)
        transaction do
          increment!(:attempts)
          update!(last_error: format_last_error(error))
        end
      end

      private

      def format_last_error(error)
        [error.message]
          .concat(error.backtrace)
          .join("\n")
          .truncate(MAX_LAST_ERROR_LENGTH)
      end
    end
  end
end
