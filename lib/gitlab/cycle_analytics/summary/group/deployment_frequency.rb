# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class DeploymentFrequency < Group::Base
          include GroupProjectsProvider
          include SummaryHelper

          def initialize(deployments:, group:, options:)
            @deployments = deployments

            super(group: group, options: options)
          end

          def title
            _('Deployment Frequency')
          end

          def value
            @value ||=
              frequency(@deployments, options[:from], options[:to] || Time.now)
          end

          def unit
            _('per day')
          end
        end
      end
    end
  end
end
