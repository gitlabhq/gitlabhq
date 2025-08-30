# frozen_string_literal: true

module AntiAbuse
  module AbuseReport
    class CreateService < ::BaseService
      attr_reader :abuse_report

      def initialize(params)
        @params = params.dup
      end

      def execute
        return error unless create_abuse_report

        ServiceResponse.success(payload: abuse_report)
      end

      private

      def create_abuse_report
        @abuse_report = ::AbuseReport.new(params)
        @abuse_report.save
      end

      def error
        ServiceResponse.error(
          message: 'AbuseReport record was not created'
        )
      end
    end
  end
end
