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
            @value ||= Deployment.joins(:project)
              .where(projects: { id: projects })
              .where("deployments.created_at > ?", @from)
              .success
              .count
          end

          private

          def projects
            Project.inside_path(@group.full_path).ids
          end
        end
      end
    end
  end
end
