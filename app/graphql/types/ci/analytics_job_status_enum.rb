# frozen_string_literal: true

module Types
  module Ci
    class AnalyticsJobStatusEnum < BaseEnum
      graphql_name 'PipelineAnalyticsJobStatus'

      value 'FAILED', description: 'Job that failed.', value: :failed
      value 'SUCCESS', description: 'Job that succeeded.', value: :success
      value 'OTHER', description: 'Job that was canceled or skipped.', value: :other
    end
  end
end
