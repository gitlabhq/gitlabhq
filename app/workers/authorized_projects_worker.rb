class AuthorizedProjectsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def self.bulk_perform_async(args_list)
    Sidekiq::Client.push_bulk('class' => self, 'args' => args_list)
  end

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    user.refresh_authorized_projects
  end
end
