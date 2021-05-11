# frozen_string_literal: true

module Projects
  module GroupLinks
    class DestroyService < BaseService
      def execute(group_link)
        return false unless group_link

        if group_link.project.private?
          TodosDestroyer::ProjectPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
        else
          TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, nil, project.id)
        end

        group_link.destroy.tap do |link|
          link.group.refresh_members_authorized_projects
        end
      end
    end
  end
end

Projects::GroupLinks::DestroyService.prepend_mod_with('Projects::GroupLinks::DestroyService')
