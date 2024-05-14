# frozen_string_literal: true

module Types
  class ProjectMemberType < BaseObject
    graphql_name 'ProjectMember'
    description 'Represents a Project Membership'

    expose_permissions Types::PermissionTypes::Project

    implements MemberInterface

    authorize :read_project

    field :project, Types::ProjectType, null: true,
      description: 'Project that User is a member of.'

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.source_id).find
    end
  end
end
