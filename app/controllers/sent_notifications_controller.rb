# frozen_string_literal: true

class SentNotificationsController < ApplicationController
  skip_before_action :authenticate_user!

  feature_category :users

  def unsubscribe
    @sent_notification = SentNotification.for(params[:id])

    return render_404 unless unsubscribe_prerequisites_met?

    return unsubscribe_and_redirect if current_user || params[:force]
  end

  private

  def unsubscribe_prerequisites_met?
    @sent_notification.present? &&
    @sent_notification.unsubscribable? &&
    noteable.present?
  end

  def noteable
    @sent_notification.noteable
  end

  def unsubscribe_and_redirect
    noteable.unsubscribe(@sent_notification.recipient, @sent_notification.project)

    flash[:notice] = _("You have been unsubscribed from this thread.")

    if current_user
      if current_user.can?(:"read_#{noteable.class.to_ability_name}", noteable)
        redirect_to noteable_path(noteable)
      else
        redirect_to root_path
      end
    else
      redirect_to new_user_session_path
    end
  end

  def noteable_path(noteable)
    case noteable
    when Issue
      issue_path(noteable)
    when MergeRequest
      merge_request_path(noteable)
    else
      root_path
    end
  end
end

SentNotificationsController.prepend_mod_with('SentNotificationsController')
