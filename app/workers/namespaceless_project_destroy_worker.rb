# frozen_string_literal: true

# Worker to destroy projects that do not have a namespace
#
# It destroys everything it can without having the info about the namespace it
# used to belong to. Projects in this state should be rare.
# The worker will reject doing anything for projects that *do* have a
# namespace. For those use ProjectDestroyWorker instead.
class NamespacelessProjectDestroyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :authentication_and_authorization

  def perform(project_id)
    begin
      project = Project.unscoped.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    return if project.namespace # Reject doing anything for projects that *do* have a namespace

    project.team.truncate

    unlink_fork(project) if project.forked?

    project.destroy!
  end

  private

  def unlink_fork(project)
    merge_requests = project.forked_from_project.merge_requests.opened.from_project(project)

    merge_requests.update_all(state_id: MergeRequest.available_states[:closed])
  end
end
