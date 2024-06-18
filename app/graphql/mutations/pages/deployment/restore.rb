# frozen_string_literal: true

module Mutations
  module Pages
    module Deployment
      class Restore < BaseMutation
        graphql_name 'RestorePagesDeployment'
        description "Restores a Pages deployment that has been scheduled for deletion."

        authorize :update_pages

        argument :id, ::Types::GlobalIDType[::PagesDeployment],
          required: true,
          description: 'ID of the Pages Deployment.'

        field :pages_deployment, Types::PagesDeploymentType,
          null: false,
          description: 'Restored Pages Deployment.'

        def resolve(id:)
          deployment = authorized_find!(id: id)

          deployment.restore

          {
            errors: errors_on_object(deployment),
            pages_deployment: deployment
          }
        end
      end
    end
  end
end
