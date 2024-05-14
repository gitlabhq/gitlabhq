# frozen_string_literal: true

module Types
  class ProjectInvitationType < BaseObject
    graphql_name 'ProjectInvitation'
    description 'Represents a Project Membership Invitation'

    expose_permissions Types::PermissionTypes::Project

    implements InvitationInterface

    authorize :admin_project

    field :project, Types::ProjectType, null: true,
      description: 'Project ID for the project of the invitation.'

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.source_id).find
    end
  end
end
