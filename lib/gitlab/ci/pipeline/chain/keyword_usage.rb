# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class KeywordUsage < Chain::Base
          include Gitlab::InternalEventsTracking

          def perform!
            track_keyword_usage
          end

          def break?
            false
          end

          private

          def track_keyword_usage
            track_keyword_usage_for('run', command.yaml_processor_result.uses_keyword?(:run))
          end

          def track_keyword_usage_for(keyword, used)
            return unless used

            track_internal_event(
              "use_#{keyword}_keyword_in_cicd_yaml",
              project: @pipeline.project,
              user: @pipeline.user
            )
          end
        end
      end
    end
  end
end
