# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
        class Finder
          def initialize(user, agent: nil, project: nil, preload: true, limit: nil)
            @user = user
            @agent = agent
            @project = project
            @limit = limit
            @preload = preload
          end

          def execute
            project_authorizations + group_authorizations
          end

          private

          attr_reader :user, :agent, :project, :preload, :limit

          def project_authorizations
            authorizations = Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization.for_user(user)
            authorizations = filter_by_agent(authorizations)
            authorizations = filter_by_project(authorizations)
            authorizations = apply_limit(authorizations)
            authorizations = apply_preload(authorizations)
            authorizations.to_a
          end

          def group_authorizations
            authorizations = Clusters::Agents::Authorizations::UserAccess::GroupAuthorization.for_user(user)
            authorizations = filter_by_agent(authorizations)
            authorizations = filter_by_project(authorizations)
            authorizations = apply_limit(authorizations)
            authorizations = apply_preload(authorizations)
            authorizations.to_a
          end

          def filter_by_agent(authorizations)
            return authorizations unless agent.present?

            authorizations.for_agent(agent)
          end

          def filter_by_project(authorizations)
            return authorizations unless project.present?

            authorizations.for_project(project)
          end

          def apply_limit(authorizations)
            return authorizations unless limit.present?

            authorizations.limit(limit)
          end

          def apply_preload(authorizations)
            return authorizations unless preload

            authorizations.preloaded
          end
        end
      end
    end
  end
end
