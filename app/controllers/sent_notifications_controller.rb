class SentNotificationsController < ApplicationController
  skip_before_action :authenticate_user!

  def unsubscribe
    @sent_notification = SentNotification.for(params[:id])
    return render_404 unless @sent_notification && @sent_notification.unsubscribable?

    noteable = @sent_notification.noteable
    noteable.unsubscribe(@sent_notification.recipient)

    flash[:notice] = "You have been unsubscribed from this thread."
    if current_user
      case noteable
      when Issue
        redirect_to issue_path(noteable)
      when MergeRequest
        redirect_to merge_request_path(noteable)
      else
        redirect_to root_path
      end
    else
      redirect_to new_user_session_path
    end
  end
end
