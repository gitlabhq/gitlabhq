# frozen_string_literal: true

module Mutations
  module Clusters
    module AgentTokens
      class Delete < BaseMutation
        graphql_name 'ClusterAgentTokenDelete'

        authorize :admin_cluster

        TokenID = ::Types::GlobalIDType[::Clusters::AgentToken]

        argument :id, TokenID,
                 required: true,
                 description: 'Global ID of the cluster agent token that will be deleted.'

        def resolve(id:)
          token = authorized_find!(id: id)
          token.destroy

          { errors: errors_on_object(token) }
        end

        private

        def find_object(id:)
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = TokenID.coerce_isolated_input(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
