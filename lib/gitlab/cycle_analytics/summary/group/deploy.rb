# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Deploy < Group::Base
          include GroupProjectsProvider

          def title
            n_('Deploy', 'Deploys', value)
          end

          def value
            @value ||= find_deployments
          end

          private

          def find_deployments
            deployments = Deployment.joins(:project).merge(Project.inside_path(group.full_path))
            deployments = deployments.where(projects: { id: options[:projects] }) if options[:projects]
            deployments = deployments.where("deployments.created_at > ?", from)
            deployments.success.count
          end
        end
      end
    end
  end
end
