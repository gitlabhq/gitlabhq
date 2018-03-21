class AuthorizedProjectsWorker
  include ApplicationWorker
  prepend WaitableWorker

  def perform(user_id)
    user = User.find_by(id: user_id)

    user&.refresh_authorized_projects
  end
end
