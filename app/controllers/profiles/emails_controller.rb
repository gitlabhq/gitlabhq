# frozen_string_literal: true

class Profiles::EmailsController < Profiles::ApplicationController
  before_action :find_email, only: [:destroy, :resend_confirmation_instructions]
  before_action -> { check_rate_limit!(:profile_add_new_email, scope: current_user, redirect_back: true) },
    only: [:create]
  before_action -> { check_rate_limit!(:profile_resend_email_confirmation, scope: current_user, redirect_back: true) },
    only: [:resend_confirmation_instructions]

  feature_category :user_profile
  urgency :low, [:index]

  def index
    @primary_email = current_user.email
    @emails = current_user.emails.order_id_desc
  end

  def create
    @email = Emails::CreateService.new(current_user, email_params.merge(user: current_user)).execute
    flash[:alert] = @email.errors.full_messages.first unless @email.errors.blank?

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

  def email_params
    params.require(:email).permit(:email)
  end

  def find_email
    @email = current_user.emails.find(params[:id])
  end
end

Profiles::EmailsController.prepend_mod
