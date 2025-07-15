# frozen_string_literal: true

module Banzai
  # Custom pipeline class that extends HTML::Pipeline to allow GitLab-specific
  # customizations and overrides of the html-pipeline gem behavior.
  class PipelineBase < ::HTML::Pipeline
    extend ::Gitlab::Utils::Override

    HTML_PIPELINE_SUBSCRIPTION = 'call_filter.html_pipeline'

    # Use thread ID to make subscription unique per thread
    def self.filter_subscription_name
      "#{HTML_PIPELINE_SUBSCRIPTION}_#{Thread.current.object_id}"
    end

    # overridden to use our own filter subscription name
    override :perform_filter
    def perform_filter(filter, doc, context, result)
      payload = default_payload(filter: filter.name, context: context, result: result)

      instrument Banzai::PipelineBase.filter_subscription_name, payload do
        filter.call(doc, context, result)
      end
    end
  end
end
