# frozen_string_literal: true

module Organizations
  module Transfer
    module Concerns
      module MissingRecordHandling
        extend ActiveSupport::Concern
        include Gitlab::Loggable

        private

        # Logs and builds an error when a record was deleted between scheduling and running the transfer.
        #
        # @return [ServiceResponse, nil] the error response, or nil when all records are present
        def missing_record_error
          message =
            if group.nil?
              'Group not found.'
            elsif old_organization.nil?
              'Old organization not found.'
            elsif new_organization.nil?
              'New organization not found.'
            end

          return unless message

          Gitlab::AppLogger.info(build_structured_payload_labkit(message: message))
          ServiceResponse.error(message: message, reason: :not_found)
        end
      end
    end
  end
end
