module Gitlab
  module CycleAnalytics
    module Summary
      class Issue < Base
        def title
          'New Issue'
        end

        def value
          @value ||= @project.issues.created_after(@from).count
        end
      end
    end
  end
end
