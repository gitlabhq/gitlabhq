# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class DeploymentFrequency < Base
        include SummaryHelper

        def initialize(deployments:, options:, project: nil)
          @deployments = deployments

          super(project: project, options: options)
        end

        def title
          _('Deployment Frequency')
        end

        def value
          @value ||= frequency(@deployments, @options[:from], @options[:to] || Time.current)
        end

        def unit
          _('per day')
        end
      end
    end
  end
end
