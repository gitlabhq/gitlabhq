# Worker to destroy projects that do not have a namespace
#
# It destroys everything it can without having the info about the namespace it
# used to belong to. Projects in this state should be rare.
# The worker will reject doing anything for projects that *do* have a
# namespace. For those use ProjectDestroyWorker instead.
class NamespacelessProjectDestroyWorker
  include ApplicationWorker
  include ExceptionBacktrace

  def perform(project_id)
    begin
      project = Project.unscoped.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    return if project.namespace  # Reject doing anything for projects that *do* have a namespace

    project.team.truncate

    unlink_fork(project) if project.forked?

    project.destroy!
  end

  private

  def unlink_fork(project)
    merge_requests = project.forked_from_project.merge_requests.opened.from_project(project)

    merge_requests.update_all(state: 'closed')

    project.forked_project_link.destroy
  end
end
