# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
        class Finder
          def initialize(user, agent:)
            @user = user
            @agent = agent
          end

          def execute
            project_authorizations + group_authorizations
          end

          private

          attr_reader :user, :agent

          def project_authorizations
            authorizations = Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization.for_user(user)
            authorizations = filter_by_agent(authorizations)
            authorizations = preload(authorizations)
            authorizations.to_a
          end

          def group_authorizations
            authorizations = Clusters::Agents::Authorizations::UserAccess::GroupAuthorization.for_user(user)
            authorizations = filter_by_agent(authorizations)
            authorizations = preload(authorizations)
            authorizations.to_a
          end

          def filter_by_agent(authorizations)
            return authorizations unless agent.present?

            authorizations.for_agent(agent)
          end

          def preload(authorizations)
            authorizations.preloaded
          end
        end
      end
    end
  end
end
