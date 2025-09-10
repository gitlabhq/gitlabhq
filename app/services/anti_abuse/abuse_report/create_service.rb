# frozen_string_literal: true

module AntiAbuse
  module AbuseReport
    class CreateService < ::BaseService
      attr_reader :abuse_report

      def initialize(params)
        @params = params.dup
      end

      def execute
        return error('Reporter param must be a valid User') unless valid_reporter?

        return error('AbuseReport record was not created') unless create_abuse_report

        ServiceResponse.success(payload: abuse_report)
      end

      private

      def create_abuse_report
        params[:organization_id] = params[:reporter].organization_id

        @abuse_report = ::AbuseReport.new(params)
        @abuse_report.save
      end

      def valid_reporter?
        return false unless params.key?(:reporter)

        params[:reporter].is_a?(User)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
