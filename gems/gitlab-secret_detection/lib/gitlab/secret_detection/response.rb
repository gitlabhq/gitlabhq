# frozen_string_literal: true

module Gitlab
  module SecretDetection
    # Response is the data object returned by the scan operation with the following structure
    #
    # +status+:: One of values from SecretDetection::Status indicating the scan operation's status.
    # +results+:: Array of SecretDetection::Finding values. Default value is nil.
    # +applied_exclusions+:: Array of exclusions that were applied during the scan. Default value is [].
    class Response
      attr_reader :results, :applied_exclusions
      attr_accessor :status

      def initialize(status, results = nil, applied_exclusions = [])
        @status = status
        @results = results
        @applied_exclusions = applied_exclusions
      end

      def ==(other)
        self.class == other.class && other.state == state
      end

      protected

      def state
        [status, results, applied_exclusions]
      end
    end
  end
end
