# frozen_string_literal: true

class SentNotificationsController < ApplicationController
  skip_before_action :authenticate_user!
  # Automatic unsubscribe by an email client should happen via a POST request.
  # See https://datatracker.ietf.org/doc/html/rfc8058
  # This allows POST requests without CSRF token.
  skip_before_action :verify_authenticity_token, only: [:unsubscribe]

  feature_category :team_planning
  urgency :low

  def unsubscribe
    @sent_notification = SentNotification.for(params[:id])

    return render_404 unless unsubscribe_prerequisites_met?

    unsubscribe_and_redirect if current_user || params[:force] || request.post?
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

    unsubscribe_issue_email_participant

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

  def unsubscribe_issue_email_participant
    return unless noteable.is_a?(Issue)
    return unless @sent_notification.recipient_id == Users::Internal.support_bot.id

    # Unsubscribe external author for legacy reasons when no issue email participant is set
    email = @sent_notification.issue_email_participant&.email || noteable.external_author

    ::IssueEmailParticipants::DestroyService.new(
      target: noteable,
      current_user: current_user,
      emails: [email],
      options: {
        context: :unsubscribe,
        skip_permission_check: true
      }
    ).execute
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
