# frozen_string_literal: true

class DeleteUserWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :authentication_and_authorization
  loggable_arguments 2

  def perform(current_user_id, delete_user_id, options = {})
    delete_user  = User.find(delete_user_id)
    current_user = User.find(current_user_id)

    Users::DestroyService.new(current_user).execute(delete_user, options.symbolize_keys)
  rescue Gitlab::Access::AccessDeniedError => e
    Gitlab::AppLogger.warn("User could not be destroyed: #{e}")
  end
end
