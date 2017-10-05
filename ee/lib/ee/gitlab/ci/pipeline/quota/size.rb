module EE
  module Gitlab
    module Ci
      module Pipeline
        module Quota
          class Size < Ci::Limit
            include ActionView::Helpers::TextHelper

            def initialize(namespace, pipeline)
              @namespace = namespace
              @pipeline = pipeline
            end

            def enabled?
              @namespace.max_pipeline_size > 0
            end

            def exceeded?
              return false unless enabled?

              excessive_seeds_count > 0
            end

            def message
              return unless exceeded?

              'Pipeline size limit exceeded by ' \
                "#{pluralize(excessive_seeds_count, 'job')}!"
            end

            private

            def excessive_seeds_count
              @excessive ||= @pipeline.seeds_size - @namespace.max_pipeline_size
            end
          end
        end
      end
    end
  end
end
