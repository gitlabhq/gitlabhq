# frozen_string_literal: true

module Gitlab
  module SecretDetection
    # Finding is a data object representing a secret finding identified within a blob
    class Finding
      attr_reader :blob_id, :status, :line_number, :type, :description
      attr_accessor :occurrences

      def initialize(blob_id, status, line_number = nil, type = nil, description = nil, occurrences = nil) # rubocop:disable Metrics/ParameterLists -- all params are needed
        @blob_id = blob_id
        @status = status
        @line_number = line_number
        @type = type
        @description = description
        @occurrences = occurrences
      end

      def ==(other)
        self.class == other.class && other.state == state
      end

      def to_h
        {
          blob_id: blob_id,
          status: status,
          line_number: line_number,
          type: type,
          description: description,
          occurrences: occurrences
        }
      end

      protected

      def state
        [blob_id, status, line_number, type, description]
      end
    end
  end
end
