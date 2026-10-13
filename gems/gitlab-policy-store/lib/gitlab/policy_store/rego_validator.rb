# frozen_string_literal: true

require "gitlab/glaz"

module Gitlab
  module PolicyStore
    # Parses a Rego program through the GLAZ engine before it is stored, so a program that
    # cannot be parsed is refused at save time with the parse error and its location.
    module RegoValidator
      extend self

      # Defensive cap. Engine messages are short today, but if a future release quotes
      # the source, this keeps the full program out of the response and logs.
      MAX_REPORTED_ERROR_BYTES = 1_000

      # The module all rules merge into. Every authored part of it already parsed on its own,
      # so a failure here is a defect in the merge, not something the caller can correct.
      MERGED_PROGRAM_FIELD = :policy_merged_program

      # @param field [String, Symbol] what the program is, for the error message
      # @param program [String] Rego source
      # @raise [Gitlab::PolicyStore::ValidationError] if an authored program does not parse
      # @raise [Gitlab::PolicyStore::EngineError] if the engine faults, or the merged module does not parse
      # @return [true]
      def validate!(field, program)
        result = engine.validate(policy_rego: program)
        raise PolicyStore::EngineError, "#{field} could not be validated" unless result.is_a?(Hash)
        return true if result[:valid]

        errors = result[:errors]
        errors = [] unless errors.is_a?(Array)
        detail = reported_errors(errors)
        raise PolicyStore::EngineError, "#{field} could not be validated" if detail.empty?

        raise invalid_program_error(field), "#{field} is invalid: #{detail}"
      rescue EncodingError
        raise invalid_program_error(field), "#{field} must be valid UTF-8"
      rescue PolicyStore::Error
        raise
      rescue StandardError
        raise PolicyStore::EngineError, "#{field} could not be validated"
      end

      private

      def engine
        ::Gitlab::Glaz.govern_policy_engine
      end

      def invalid_program_error(field)
        field.to_sym == MERGED_PROGRAM_FIELD ? PolicyStore::EngineError : PolicyStore::ValidationError
      end

      def reported_errors(errors)
        errors.map do |error|
          message = truncated(error[:message].to_s, MAX_REPORTED_ERROR_BYTES)
          location = error[:location].to_s.strip

          location.empty? ? message : "#{message} (at #{location})"
        end.join("; ")
      end

      def truncated(text, limit)
        return text if text.bytesize <= limit

        "#{text.byteslice(0, limit).scrub('')}..."
      end
    end
  end
end
