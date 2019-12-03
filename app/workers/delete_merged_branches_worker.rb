# frozen_string_literal: true

class DeleteMergedBranchesWorker
  include ApplicationWorker

  feature_category :source_code_management

  def perform(project_id, user_id)
    begin
      project = Project.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    begin
      ::Branches::DeleteMergedService.new(project, user).execute
    rescue Gitlab::Access::AccessDeniedError
      return
    end
  end
end
