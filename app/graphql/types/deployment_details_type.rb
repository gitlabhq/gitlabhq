# frozen_string_literal: true

module Types
  class DeploymentDetailsType < DeploymentType
    graphql_name 'DeploymentDetails'
    description 'The details of the deployment'
    authorize :read_deployment
  end
end
