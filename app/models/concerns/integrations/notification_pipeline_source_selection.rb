# frozen_string_literal: true

module Integrations
  module NotificationPipelineSourceSelection
    extend ActiveSupport::Concern

    private

    def notify_for_pipeline_source?(data)
      source = data.dig(:object_attributes, :source)

      case source
      when 'parent_pipeline'
        return true unless Feature.enabled?(:pipelines_email_notify_child_pipelines, parent.root_ancestor)

        notify_child_pipelines?
      else
        true # notify for all other sources by default
      end
    end
  end
end
