class CreateBranchService
  def execute(project, branch_name, ref, current_user)
    repository = project.repository
    repository.add_branch(branch_name, ref)
    new_branch = repository.find_branch(branch_name)

    if new_branch
      Event.create_ref_event(project, current_user, new_branch, 'add')
    end

    new_branch
  end
end
