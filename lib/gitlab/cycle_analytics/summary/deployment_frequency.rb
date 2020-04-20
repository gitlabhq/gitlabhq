# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class DeploymentFrequency < Base
        include SummaryHelper

        def initialize(deployments:, from:, to: nil, project: nil)
          @deployments = deployments

          super(project: project, from: from, to: to)
        end

        def title
          _('Deployment Frequency')
        end

        def value
          @value ||=
            frequency(@deployments, @from, @to || Time.now)
        end

        def unit
          _('per day')
        end
      end
    end
  end
end
