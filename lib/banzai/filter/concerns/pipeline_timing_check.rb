# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      # This provides the ability to check if the pipeline has run longer
      # than some maximum. Usually a filter will check this and simply
      # return if exceeded.
      #
      # This allows for filters to be skipped in order to keep pipeline
      # execution time within a certain threshold.
      #
      # If the check is used for a filter that does sanitization or redaction,
      # then the TimeoutFilterHandler::COMPLEX_MARKDOWN_MESSAGE should be returned
      # to ensure we don't return compromised HTML.
      module PipelineTimingCheck
        extend ActiveSupport::Concern

        # This value was chosen to achieve roughly 20 requests per second
        # when using the API (3 secs), plus a 2 sec buffer
        MAX_PIPELINE_SECONDS = 5

        def call
          return doc if exceeded_pipeline_max?

          super
        end

        def exceeded_pipeline_max?
          return false if Gitlab::RenderTimeout.banzai_timeout_disabled?

          result[:pipeline_timing] && result[:pipeline_timing] > MAX_PIPELINE_SECONDS
        end
      end
    end
  end
end
