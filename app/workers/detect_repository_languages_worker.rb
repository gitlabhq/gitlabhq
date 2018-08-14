# frozen_string_literal: true

class DetectRepositoryLanguagesWorker
  include ApplicationWorker
  include ExceptionBacktrace
  include ExclusiveLeaseGuard

  sidekiq_options retry: 1

  LEASE_TIMEOUT = 300

  attr_reader :project

  def perform(project_id, user_id)
    @project = Project.find_by(id: project_id)
    user = User.find_by(id: user_id)
    return unless project && user

    return if Feature.disabled?(:repository_languages, project.namespace)

    try_obtain_lease do
      ::Projects::DetectRepositoryLanguagesService.new(project, user).execute
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
