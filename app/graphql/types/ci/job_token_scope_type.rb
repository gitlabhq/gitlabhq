# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Authorization is in the resolver based on the parent project
  # TODO: remove once https://gitlab.com/gitlab-org/govern/authorization/team-tasks/-/issues/87 is resolved
  module Ci
    class JobTokenScopeType < BaseObject
      graphql_name 'CiJobTokenScopeType'

      field :projects,
        Types::ProjectType.connection_type,
        null: false,
        description: 'Allow list of projects that can be accessed by CI Job tokens created by the project.',
        method: :outbound_projects,
        deprecated: {
          reason: 'The `projects` attribute is being deprecated. Use `outbound_allowlist`',
          milestone: '15.9'
        }

      field :outbound_allowlist,
        Types::ProjectType.connection_type,
        null: false,
        description: "Allow list of projects that are accessible using the current project's CI Job tokens.",
        method: :outbound_projects

      field :inbound_allowlist,
        Types::Ci::JobTokenAccessibleProjectType.connection_type,
        null: false,
        description: "Allowlist of projects that can access the current project " \
          "by authenticating with a CI/CD job token.",
        method: :inbound_projects

      field :groups_allowlist,
        Types::Ci::JobTokenAccessibleGroupType.connection_type,
        null: false,
        description: "Allowlist of groups that can access the current project " \
          "by authenticating with a CI/CD job token.",
        method: :groups

      field :inbound_allowlist_count,
        GraphQL::Types::Int,
        null: false,
        description: "Count of projects that can access the current project " \
          "by authenticating with a CI/CD job token. " \
          "The count does not include nested projects.",
        method: :inbound_projects_count

      field :groups_allowlist_count,
        GraphQL::Types::Int,
        null: false,
        description: "Count of groups that can access the current project " \
          "by authenticating with a CI/CD job token. " \
          "The count does not include subgroups.",
        method: :groups_count

      field :group_allowlist_autopopulated_ids,
        [::Types::GlobalIDType[::Group]],
        null: false,
        description: 'List of IDs of groups which have been created by the  ' \
          'autopopulation process.',
        method: :autopopulated_group_ids

      field :inbound_allowlist_autopopulated_ids,
        [::Types::GlobalIDType[::Project]],
        null: false,
        description: 'List of IDs of projects which have been created by the  ' \
          'autopopulation process.',
        method: :autopopulated_inbound_project_ids
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
