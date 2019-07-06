# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Deploy < Group::Base
          def title
            n_('Deploy', 'Deploys', value)
          end

          def value
            @value ||= find_deployments
          end

          private

          def find_deployments
            deployments = Deployment.joins(:project)
              .where(projects: { id: projects })
              .where("deployments.created_at > ?", @from)
            deployments = deployments.where(projects: { id: @options[:projects] }) if @options[:projects]
            deployments.success.count
          end

          def projects
            Project.inside_path(@group.full_path).ids
          end
        end
      end
    end
  end
end
