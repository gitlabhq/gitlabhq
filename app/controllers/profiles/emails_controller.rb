# frozen_string_literal: true

class Profiles::EmailsController < Profiles::ApplicationController
  before_action :find_email, only: [:destroy, :resend_confirmation_instructions]
  before_action -> { rate_limit!(:profile_add_new_email) }, only: [:create]
  before_action -> { rate_limit!(:profile_resend_email_confirmation) }, only: [:resend_confirmation_instructions]

  feature_category :users

  def index
    @primary_email = current_user.email
    @emails = current_user.emails.order_id_desc
  end

  def create
    @email = Emails::CreateService.new(current_user, email_params.merge(user: current_user)).execute
    unless @email.errors.blank?
      flash[:alert] = @email.errors.full_messages.first
    end

    redirect_to profile_emails_url
  end

  def destroy
    Emails::DestroyService.new(current_user, user: current_user).execute(@email)

    respond_to do |format|
      format.html { redirect_to profile_emails_url, status: :found }
      format.js { head :ok }
    end
  end

  def resend_confirmation_instructions
    if Emails::ConfirmService.new(current_user, user: current_user).execute(@email)
      flash[:notice] = _("Confirmation email sent to %{email}") % { email: @email.email }
    else
      flash[:alert] = _("There was a problem sending the confirmation email")
    end

    redirect_to profile_emails_url
  end

  private

  def rate_limit!(action)
    rate_limiter = ::Gitlab::ApplicationRateLimiter

    if rate_limiter.throttled?(action, scope: current_user)
      rate_limiter.log_request(request, action, current_user)

      redirect_back_or_default(options: { alert: _('This action has been performed too many times. Try again later.') })
    end
  end

  def email_params
    params.require(:email).permit(:email)
  end

  def find_email
    @email = current_user.emails.find(params[:id])
  end
end
