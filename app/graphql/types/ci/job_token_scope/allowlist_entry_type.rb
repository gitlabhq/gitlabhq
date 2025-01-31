# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by parent class
      class AllowlistEntryType < BaseObject
        graphql_name 'CiJobTokenScopeAllowlistEntry'
        description 'Represents an allowlist entry for the CI_JOB_TOKEN'

        connection_type_class Types::CountableConnectionType

        field :source_project,
          Types::ProjectType,
          null: false,
          description: "Project that owns the allowlist entry."

        field :target,
          Ci::JobTokenScope::TargetType,
          null: true,
          description: 'Group or project allowed by the entry.'

        field :direction,
          GraphQL::Types::String,
          null: true,
          description: 'Direction of access. Defaults to INBOUND.'

        field :default_permissions,
          GraphQL::Types::Boolean,
          description: 'Indicates whether default permissions are enabled (true) or fine-grained permissions are ' \
            'enabled (false).'

        field :job_token_policies,
          [Types::Ci::JobTokenScope::PoliciesEnum],
          null: true,
          description: 'List of policies for the entry.',
          experiment: { milestone: '17.5' }

        field :added_by,
          Types::UserType,
          null: true,
          description: 'User that added the entry.'

        field :created_at,
          Types::TimeType,
          null: false,
          description: 'When the entry was created.'

        field :autopopulated,
          GraphQL::Types::Boolean,
          null: true,
          description: 'Indicates whether the entry is created by the autopopulation process.'

        def source_project
          Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.source_project_id).find
        end

        def target
          case object
          when ::Ci::JobToken::ProjectScopeLink
            Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.target_project_id).find
          when ::Ci::JobToken::GroupScopeLink
            Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.target_group_id).find
          end
        end

        def direction
          case object
          when ::Ci::JobToken::ProjectScopeLink
            object.direction
          when ::Ci::JobToken::GroupScopeLink
            'inbound'
          end
        end

        def default_permissions
          Feature.enabled?(:add_policies_to_ci_job_token, object.source_project) ? object.default_permissions : true
        end

        def job_token_policies
          return unless Feature.enabled?(:add_policies_to_ci_job_token, object.source_project)

          object.job_token_policies
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
