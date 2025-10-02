# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class CollaboratorImporter
        attr_reader :collaborator, :project, :client, :members_finder

        # collaborator - An instance of `Gitlab::GithubImport::Representation::Collaborator`
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(collaborator, project, client)
          @collaborator = collaborator
          @project = project
          @client = client
          @members_finder = ::MembersFinder.new(project, project.creator)
        end

        def execute
          user_finder = GithubImport::UserFinder.new(project, client)
          user_id = user_finder.user_id_for(collaborator)
          return if user_id.nil?

          access_level = map_access_level

          if user_finder.source_user_accepted?(collaborator)
            return if mapped_to_project_bot?(user_id)

            membership = existing_user_membership(user_id)
            return if membership && membership[:access_level] > map_access_level

            create_membership!(user_id, access_level)
          else
            ::Import::PlaceholderMemberships::CreateService.new(
              source_user: user_finder.source_user(collaborator),
              access_level: access_level,
              project: project
            ).execute
          end
        end

        private

        # We don't want to create a new membership for a project bot,
        # as they are not allowed to be members of other groups or projects.
        def mapped_to_project_bot?(user_id)
          ::User.find_by_id(user_id)&.project_bot?
        end

        def existing_user_membership(user_id)
          members_finder.execute(include_relations: member_finder_relations).find_by_user_id(user_id)
        end

        def member_finder_relations
          ::Import::ReassignPlaceholderUserRecordsService::PROJECT_FINDER_MEMBER_RELATIONS
        end

        def map_access_level
          access_level =
            case collaborator[:role_name]
            when 'read' then Gitlab::Access::GUEST
            when 'triage' then Gitlab::Access::REPORTER
            when 'write' then Gitlab::Access::DEVELOPER
            when 'maintain' then Gitlab::Access::MAINTAINER
            when 'admin' then Gitlab::Access::OWNER
            end
          return access_level if access_level

          raise(
            ::Gitlab::GithubImport::ObjectImporter::NotRetriableError,
            "Unknown GitHub role: #{collaborator[:role_name]}"
          )
        end

        def create_membership!(user_id, access_level)
          ::ProjectMember.create!(
            importing: true,
            source: project,
            access_level: access_level,
            user_id: user_id,
            member_namespace_id: project.project_namespace_id,
            created_by_id: project.creator_id
          )
        end
      end
    end
  end
end
