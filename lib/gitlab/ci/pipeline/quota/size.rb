# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Quota
        class Size < ::Gitlab::Ci::Limit
          include ::Gitlab::Utils::StrongMemoize
          include ActionView::Helpers::TextHelper

          LOGGABLE_JOBS_COUNT = 2000 # log large pipelines to determine a future global pipeline size limit

          def initialize(namespace, pipeline, command)
            @namespace = namespace
            @pipeline = pipeline
            @command = command
          end

          def enabled?
            ci_pipeline_size_limit > 0
          end

          def exceeded?
            return false unless enabled?

            seeds_size > ci_pipeline_size_limit
          end

          def log_exceeded_limit?
            seeds_size > LOGGABLE_JOBS_COUNT
          end

          def message
            doc_link = Rails.application.routes.url_helpers.help_page_url('ci/debugging.md',
              anchor: 'pipeline-with-many-jobs-fails-to-start')
            "The number of jobs has exceeded the limit of #{ci_pipeline_size_limit}. " \
              "Try splitting the configuration with parent-child-pipelines #{doc_link}"
          end

          private

          def ci_pipeline_size_limit
            @namespace.actual_limits.ci_pipeline_size
          end
          strong_memoize_attr :ci_pipeline_size_limit

          def seeds_size
            @command.pipeline_seed.size
          end
        end
      end
    end
  end
end
