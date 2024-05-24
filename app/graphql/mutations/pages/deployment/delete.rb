# frozen_string_literal: true

module Mutations
  module Pages
    module Deployment
      class Delete < BaseMutation
        graphql_name 'DeletePagesDeployment'
        description "Deletes a Pages deployment."

        authorize :update_pages

        argument :id, ::Types::GlobalIDType[::PagesDeployment],
          required: true,
          description: 'ID of the Pages Deployment.'

        def resolve(id:)
          deployment = authorized_find!(id: id)

          deployment.deactivate

          {
            errors: errors_on_object(deployment)
          }
        end
      end
    end
  end
end
