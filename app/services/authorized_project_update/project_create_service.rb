# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectCreateService < BaseService
    BATCH_SIZE = 1000

    def initialize(project)
      @project = project
    end

    def execute
      group = project.group

      unless group
        return ServiceResponse.error(message: 'Project does not have a group')
      end

      group.members_from_self_and_ancestors_with_effective_access_level
           .each_batch(of: BATCH_SIZE, column: :user_id) do |members|
        attributes = members.map do |member|
          { user_id: member.user_id, project_id: project.id, access_level: member.access_level }
        end

        ProjectAuthorization.insert_all(attributes)
      end

      ServiceResponse.success
    end

    private

    attr_reader :project
  end
end
