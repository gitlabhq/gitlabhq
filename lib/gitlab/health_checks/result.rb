# frozen_string_literal: true

module Gitlab
  module HealthChecks
    Result = Struct.new(:name, :success, :message, :labels) do
      def payload
        {
          status: success ? 'ok' : 'failed',
          message: message,
          labels: labels
        }.compact
      end
    end
  end
end
