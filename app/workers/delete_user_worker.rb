class DeleteUserWorker
  include ApplicationWorker

  def perform(current_user_id, delete_user_id, options = {})
    delete_user  = User.find(delete_user_id)
    current_user = User.find(current_user_id)

    ::Users::DestroyService.new(current_user).execute(delete_user, options.symbolize_keys)
  rescue Gitlab::Access::AccessDeniedError => e
    Rails.logger.warn("User could not be destroyed: #{e}")
  end
end
