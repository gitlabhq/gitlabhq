# frozen_string_literal: true

class DeleteUserWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :user_management
  loggable_arguments 2

  def perform(current_user_id, delete_user_id, options = {})
    delete_user = User.find_by_id(delete_user_id)
    return unless delete_user.present?

    return if delete_user.banned? && ::Feature.enabled?(:delay_delete_own_user)

    current_user = User.find_by_id(current_user_id)
    return unless current_user.present?

    Users::DestroyService.new(current_user).execute(delete_user, options.symbolize_keys)
  rescue Gitlab::Access::AccessDeniedError => e
    Gitlab::AppLogger.warn("User could not be destroyed: #{e}")
  end
end
