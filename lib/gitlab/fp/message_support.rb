# frozen_string_literal: true

require 'active_model/errors'

module Gitlab
  module Fp
    module MessageSupport
      # @param [Class] base
      # @return void
      def self.extended(base)
        base.class_eval do
          private_class_method :generate_error_response_from_message
        end
      end

      # @param [Gitlab::Fp::Message] message
      # @param [Symbol] reason
      # @return [Hash]
      def generate_error_response_from_message(message:, reason:)
        details_string =
          case message.content
          in {}
            nil
          in { details: String => error_details }
            error_details
          in { errors: ActiveModel::Errors => errors }
            errors.full_messages.join(', ')
          else
            raise "Unexpected message content, add a case to pattern match it and convert it to a String."
          end
        # NOTE: Safe navigation operator is used here to prevent a type error, because Module#name is a 'String | nil'
        message_string = message.class.name&.demodulize&.underscore&.humanize
        error_message = details_string ? "#{message_string}: #{details_string}" : message_string
        { status: :error, message: error_message, reason: reason }
      end
    end
  end
end
