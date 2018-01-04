class DeleteMergedBranchesWorker
  include ApplicationWorker

  def perform(project_id, user_id)
    begin
      project = Project.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    begin
      DeleteMergedBranchesService.new(project, user).execute
    rescue Gitlab::Access::AccessDeniedError
      return
    end
  end
end
