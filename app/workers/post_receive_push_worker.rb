# frozen_string_literal: true

class PostReceivePushWorker
  include ApplicationWorker
  prepend WaitableWorker

  queue_namespace :post_receive

  def perform(job_kind, project_id, user_id, oldrev, newrev, ref)
    project = Project.find_by(id: project_id)
    user = User.find_by(id: user_id)

    job_kind.constantize.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref).execute
  end
end
