module Issues
  class CreateBranchService < Issues::BaseService
    def execute(issue, branch_name, ref)
      ::CreateBranchService.new(project, current_user).execute(branch_name, ref).tap do |result|
        if result[:status] == :success
          SystemNoteService.new_issue_branch(issue, project, current_user, result[:branch].name)
        end
      end
    end
  end
end
