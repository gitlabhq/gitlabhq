# frozen_string_literal: true

class ProjectDestroyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :source_code_management
  tags :requires_disk_io, :exclude_from_kubernetes

  def perform(project_id, user_id, params)
    project = Project.find(project_id)
    user = User.find(user_id)

    ::Projects::DestroyService.new(project, user, params.symbolize_keys).execute
  rescue ActiveRecord::RecordNotFound => error
    logger.error("Failed to delete project (#{project_id}): #{error.message}")
  end
end
