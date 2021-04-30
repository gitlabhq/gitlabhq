# frozen_string_literal: true

class RepositoryRemoveRemoteWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include ExclusiveLeaseGuard

  feature_category :source_code_management
  loggable_arguments 1

  LEASE_TIMEOUT = 1.hour

  attr_reader :project, :remote_name

  def perform(project_id, remote_name)
    @remote_name = remote_name
    @project = Project.find_by_id(project_id)

    return unless @project

    logger.info("Removing remote #{remote_name} from project #{project.id}")

    try_obtain_lease do
      remove_remote = @project.repository.remove_remote(remote_name)

      if remove_remote
        logger.info("Remote #{remote_name} was successfully removed from project #{project.id}")
      else
        logger.error("Could not remove remote #{remote_name} from project #{project.id}")
      end
    end
  end

  def lease_timeout
    LEASE_TIMEOUT
  end

  def lease_key
    "remove_remote_#{project.id}_#{remote_name}"
  end
end
