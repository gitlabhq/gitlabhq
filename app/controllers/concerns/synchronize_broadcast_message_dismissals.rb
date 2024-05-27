# frozen_string_literal: true

module SynchronizeBroadcastMessageDismissals
  extend ActiveSupport::Concern

  def synchronize_broadcast_message_dismissals
    message_ids = System::BroadcastMessage.current.map(&:id)

    Users::BroadcastMessageDismissal.valid_dismissals.for_user_and_broadcast_message(current_user, message_ids)
      .find_each do |dismissal|
      create_dismissal_cookie(dismissal) if cookies[dismissal.cookie_key].blank?
    end
  end

  private

  def create_dismissal_cookie(dismissal)
    cookies[dismissal.cookie_key] = { value: true, expires: dismissal.expires_at }
  end
end
