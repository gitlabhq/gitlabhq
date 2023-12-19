# frozen_string_literal: true

module Gitlab
  module SecretDetection
    # Response is the data object returned by the scan operation with the following structure
    #
    # +status+:: One of values from SecretDetection::Status indicating the scan operation's status
    # +results+:: Array of SecretDetection::Finding values. Default value is nil.
    class Response
      attr_reader :status, :results

      def initialize(status, results = nil)
        @status = status
        @results = results
      end

      def ==(other)
        self.class == other.class && other.state == state
      end

      protected

      def state
        [status, results]
      end
    end
  end
end
