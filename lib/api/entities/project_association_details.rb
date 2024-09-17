# frozen_string_literal: true

module API
  module Entities
    class ProjectAssociationDetails < Entities::ProjectIdentity
      expose :access_levels do
        expose :project_access_level do |project, options|
          project.member(options[:current_user])&.access_level
        end

        expose :group_access_level do |project, options|
          project.group.highest_group_member(options[:current_user])&.access_level if project.group
        end
      end

      expose :visibility, documentation: { type: 'string', example: 'public' }
      expose :web_url, documentation: { type: 'string', example: 'https://gitlab.example.com/gitlab/gitlab' }
      expose :namespace, using: 'API::Entities::NamespaceBasic'
    end
  end
end
