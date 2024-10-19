# frozen_string_literal: true

class DeleteMergedBranchesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3

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
    end
  end
end
