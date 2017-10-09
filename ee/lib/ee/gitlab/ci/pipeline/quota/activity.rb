module EE
  module Gitlab
    module Ci
      module Pipeline
        module Quota
          class Activity < Ci::Limit
            include ActionView::Helpers::TextHelper

            def initialize(namespace, project)
              @namespace = namespace
              @project = project
            end

            def enabled?
              @namespace.max_active_pipelines > 0
            end

            def exceeded?
              return false unless enabled?

              excessive_pipelines_count > 0
            end

            def message
              return unless exceeded?

              'Active pipelines limit exceeded by ' \
                "#{pluralize(excessive_pipelines_count, 'pipeline')}!"
            end

            private

            def excessive_pipelines_count
              @excessive ||= alive_pipelines_count - max_active_pipelines_count
            end

            def alive_pipelines_count
              @project.pipelines.alive.count
            end

            def max_active_pipelines_count
              @namespace.max_active_pipelines
            end
          end
        end
      end
    end
  end
end
