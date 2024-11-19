# frozen_string_literal: true

class DetectRepositoryLanguagesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :sticky
  include ExceptionBacktrace
  include ExclusiveLeaseGuard

  sidekiq_options retry: 1
  feature_category :source_code_management

  LEASE_TIMEOUT = 300

  attr_reader :project

  def perform(project_id, user_id = nil)
    @project = Project.find_by_id(project_id)
    return unless project

    try_obtain_lease do
      ::Projects::DetectRepositoryLanguagesService.new(project).execute
    end
  end

  private

  def lease_timeout
    LEASE_TIMEOUT
  end

  def lease_key
    "gitlab:detect_repository_languages:#{project.id}"
  end
end
