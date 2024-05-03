# frozen_string_literal: true

module Types
  module Ci
    class PipelineStatusEnum < BaseEnum
      STATUSES_DESCRIPTION = {
        created: 'Pipeline has been created.',
        waiting_for_resource: 'A resource (for example, a runner) that the pipeline requires to run is unavailable.',
        preparing: 'Pipeline is preparing to run.',
        waiting_for_callback: 'Pipeline is waiting for an external action.',
        pending: 'Pipeline has not started running yet.',
        running: 'Pipeline is running.',
        failed: 'At least one stage of the pipeline failed.',
        success: 'Pipeline completed successfully.',
        canceling: 'Pipeline is in the process of canceling.',
        canceled: 'Pipeline was canceled before completion.',
        skipped: 'Pipeline was skipped.',
        manual: 'Pipeline needs to be manually started.',
        scheduled: 'Pipeline is scheduled to run.'
      }.freeze

      STATUSES_DESCRIPTION.each do |state, description|
        value state.to_s.upcase,
          description: description,
          value: state.to_s
      end
    end
  end
end
