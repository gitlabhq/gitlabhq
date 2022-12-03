# frozen_string_literal: true

module Types
  # If you're considering to add a new field in DeploymentType, please follow this guideline:
  # - If the field is preloadable in batch, define it in DeploymentType.
  #   In this case, you should extend DeploymentsResolver logic to preload the field. Also, add a new test that
  #   fetching the specific field for multiple deployments doesn't cause N+1 query problem.
  # - If the field is NOT preloadable in batch, define it in DeploymentDetailsType.
  #   This type can be only fetched for a single deployment, so you don't need to take care of the preloading.
  class DeploymentType < BaseObject
    graphql_name 'Deployment'
    description 'The deployment of an environment'

    present_using ::Deployments::DeploymentPresenter

    authorize :read_deployment

    expose_permissions Types::PermissionTypes::Deployment

    field :id,
      GraphQL::Types::ID,
      description: 'Global ID of the deployment.'

    field :iid,
      GraphQL::Types::ID,
      description: 'Project-level internal ID of the deployment.'

    field :ref,
      GraphQL::Types::String,
      description: 'Git-Ref that the deployment ran on.'

    field :tag,
      GraphQL::Types::Boolean,
      description: 'True or false if the deployment ran on a Git-tag.'

    field :sha,
      GraphQL::Types::String,
      description: 'Git-SHA that the deployment ran on.'

    field :created_at,
      Types::TimeType,
      description: 'When the deployment record was created.'

    field :updated_at,
      Types::TimeType,
      description: 'When the deployment record was updated.'

    field :finished_at,
      Types::TimeType,
      description: 'When the deployment finished.'

    field :status,
      Types::DeploymentStatusEnum,
      description: 'Status of the deployment.'

    field :commit,
      Types::CommitType,
      description: 'Commit details of the deployment.',
      calls_gitaly: true

    field :job,
      Types::Ci::JobType,
      description: 'Pipeline job of the deployment.',
      method: :build

    field :triggerer,
      Types::UserType,
      description: 'User who executed the deployment.',
      method: :deployed_by
  end
end
