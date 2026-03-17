# frozen_string_literal: true

module Integrations
  module NotificationPipelineStatusSelection
    extend ActiveSupport::Concern

    private

    def notify_for_pipeline?(data)
      case data.dig(:object_attributes, :status)
      when 'failed'
        notify_for_failed_pipeline?(data)
      when 'success'
        notify_for_successful_pipeline?(data)
      else
        false
      end
    end

    def notify_for_failed_pipeline?(data)
      return true unless notify_only_when_pipeline_status_changes?

      data.dig(:object_attributes, :ref_status_name) == "broken"
    end

    def notify_for_successful_pipeline?(data)
      return false if notify_only_broken_pipelines?
      return true unless notify_only_when_pipeline_status_changes?

      data.dig(:object_attributes, :ref_status_name) == "fixed"
    end
  end
end
