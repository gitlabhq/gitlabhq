module Projects
  class MoveAccessService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      @project.with_transaction_returning_status do
        if @project.namespace != source_project.namespace
          @project.run_after_commit do
            source_project.namespace.refresh_project_authorizations
            self.namespace.refresh_project_authorizations
          end
        end

        ::Projects::MoveProjectMembersService.new(@project, @current_user)
          .execute(source_project, remove_remaining_elements: remove_remaining_elements)
        ::Projects::MoveProjectGroupLinksService.new(@project, @current_user)
          .execute(source_project, remove_remaining_elements: remove_remaining_elements)
        ::Projects::MoveProjectAuthorizationsService.new(@project, @current_user)
          .execute(source_project, remove_remaining_elements: remove_remaining_elements)

        success
      end
    end
  end
end
