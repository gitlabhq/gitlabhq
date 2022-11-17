# frozen_string_literal: true

module Types
  class DeploymentDetailsType < DeploymentType
    graphql_name 'DeploymentDetails'
    description 'The details of the deployment'
    authorize :read_deployment
    present_using ::Deployments::DeploymentPresenter

    field :tags,
          [Types::DeploymentTagType],
          description: 'Git tags that contain this deployment.',
          calls_gitaly: true
  end
end

Types::DeploymentDetailsType.prepend_mod_with('Types::DeploymentDetailsType')
