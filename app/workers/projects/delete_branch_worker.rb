# frozen_string_literal: true

module Projects
  class DeleteBranchWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :source_code_management
    urgency :high
    idempotent!

    def perform(project_id, user_id, branch_name)
      project = Project.find_by_id(project_id)
      user = User.find_by_id(user_id)

      return unless project.present? && user.present?
      return unless project.repository.branch_exists?(branch_name)

      delete_service_result = ::Branches::DeleteService.new(project, user)
        .execute(branch_name)

      # Only want to raise on 400 to avoid permission and non existant branch error
      return unless delete_service_result[:http_status] == 400

      delete_service_result.track_and_raise_exception
    end
  end
end
