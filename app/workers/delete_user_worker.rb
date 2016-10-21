class DeleteUserWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(current_user_id, delete_user_id, options = {})
    delete_user  = User.find(delete_user_id)
    current_user = User.find(current_user_id)

    DeleteUserService.new(current_user).execute(delete_user, options.symbolize_keys)
  end
end
