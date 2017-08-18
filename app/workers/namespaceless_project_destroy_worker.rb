# Worker to destroy projects that do not have a namespace
#
# It destroys everything it can without having the info about the namespace it
# used to belong to. Projects in this state should be rare.
# The worker will reject doing anything for projects that *do* have a
# namespace. For those use ProjectDestroyWorker instead.
class NamespacelessProjectDestroyWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def self.bulk_perform_async(args_list)
    Sidekiq::Client.push_bulk('class' => self, 'queue' => sidekiq_options['queue'], 'args' => args_list)
  end

  def perform(project_id)
    begin
      project = Project.unscoped.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end
    return unless project.namespace_id.nil?  # Reject doing anything for projects that *do* have a namespace

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
