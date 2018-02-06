class Profiles::EmailsController < Profiles::ApplicationController
  before_action :find_email, only: [:destroy, :resend_confirmation_instructions]

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
      format.html { redirect_to profile_emails_url, status: 302 }
      format.js { head :ok }
    end
  end

  def resend_confirmation_instructions
    if Emails::ConfirmService.new(current_user, user: current_user).execute(@email)
      flash[:notice] = "Confirmation email sent to #{@email.email}"
    else
      flash[:alert] = "There was a problem sending the confirmation email"
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
