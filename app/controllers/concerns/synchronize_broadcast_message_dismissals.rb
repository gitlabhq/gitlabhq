# frozen_string_literal: true

module SynchronizeBroadcastMessageDismissals
  extend ActiveSupport::Concern

  def synchronize_broadcast_message_dismissals
    Users::BroadcastMessageDismissalFinder.new(current_user).execute
      .find_each do |dismissal|
      create_dismissal_cookie(dismissal) if cookies[dismissal.cookie_key].blank?
    end
  end

  private

  def create_dismissal_cookie(dismissal)
    cookies[dismissal.cookie_key] = { value: true, expires: dismissal.expires_at }
  end
end
