# frozen_string_literal: true

module Types
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
      GraphQL::Types::String,
      description: 'Project-level internal ID of the deployment.'

    field :ref,
      GraphQL::Types::String,
      description: 'Git-Ref that the deployment ran on.'

    field :ref_path,
      GraphQL::Types::String,
      description: 'Path to the Git-Ref that the deployment ran on.'

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
      Types::Repositories::CommitType,
      description: 'Commit details of the deployment.',
      calls_gitaly: true

    field :job,
      Types::Ci::JobType,
      description: 'Pipeline job of the deployment.'

    field :triggerer,
      Types::UserType,
      description: 'User who executed the deployment.',
      method: :deployed_by

    field :tags,
      [Types::DeploymentTagType],
      description: 'Git tags that contain this deployment. ' \
        'This field can only be resolved for two deployments in any single request.',
      calls_gitaly: true do
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 2
    end

    field :web_path,
      GraphQL::Types::String, null: true,
      description: 'Web path to the deployment page.'
  end
end

Types::DeploymentType.prepend_mod_with('Types::DeploymentType')
