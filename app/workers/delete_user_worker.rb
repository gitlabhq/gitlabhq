# frozen_string_literal: true

class DeleteUserWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :user_management
  loggable_arguments 2

  def perform(current_user_id, delete_user_id, options = {})
    # Deleting a user deletes many different resources, so a higher threshold is OK for now
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464672', new_threshold: 200)

    delete_user = User.find_by_id(delete_user_id)
    return unless delete_user.present?

    return if skip_own_account_deletion?(delete_user)

    current_user = User.find_by_id(current_user_id)
    return unless current_user.present?

    Users::DestroyService.new(current_user).execute(delete_user, options.symbolize_keys)
  rescue Gitlab::Access::AccessDeniedError => e
    Gitlab::AppLogger.warn("User could not be destroyed: #{e}")
  end

  private

  def skip_own_account_deletion?(user)
    return false unless ::Feature.enabled?(:delay_delete_own_user)

    skip =
      if user.banned?
        true
      else
        # User is blocked when they delete their own account. Skip record deletion
        # when user has been unblocked (e.g. when the user's account is reinstated
        # by Trust & Safety)
        user.deleted_own_account? && !user.blocked?
      end

    if skip
      user.custom_attributes.by_key(UserCustomAttribute::DELETED_OWN_ACCOUNT_AT).first&.destroy
      UserCustomAttribute.set_skipped_account_deletion_at(user)

      Gitlab::AppLogger.info(
        message: 'Skipped own account deletion.',
        reason: "User has been #{user.banned? ? 'banned' : 'unblocked'}.",
        user_id: user.id,
        username: user.username
      )
    end

    skip
  end
end
