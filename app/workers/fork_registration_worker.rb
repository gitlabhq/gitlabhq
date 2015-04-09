class ForkRegistrationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(from_project_id, to_project_id, private_token)
    from_project = Project.find(from_project_id)
    to_project = Project.find(to_project_id)

    from_project.gitlab_ci_service.fork_registration(to_project, private_token)
  end
end
