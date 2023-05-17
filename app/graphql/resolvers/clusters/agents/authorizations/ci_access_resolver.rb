# frozen_string_literal: true

module Resolvers
  module Clusters
    module Agents
      module Authorizations
        class CiAccessResolver < BaseResolver
          type Types::Clusters::Agents::Authorizations::CiAccessType, null: true

          alias_method :project, :object

          def resolve(*)
            ::Clusters::Agents::Authorizations::CiAccess::Finder.new(project).execute
          end
        end
      end
    end
  end
end
