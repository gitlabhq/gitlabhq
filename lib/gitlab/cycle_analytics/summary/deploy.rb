module Gitlab
  module CycleAnalytics
    module Summary
      class Deploy < Base
        def title
          n_('Deploy', 'Deploys', value)
        end

        def value
          @value ||= @project.deployments.success.where("created_at > ?", @from).count
        end
      end
    end
  end
end
