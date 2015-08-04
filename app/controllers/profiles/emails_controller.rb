class Profiles::EmailsController < Profiles::ApplicationController
  def index
    @primary = current_user.email
    @emails = current_user.emails
  end

  def create
    @email = current_user.emails.new(email_params)

    if @email.save
      NotificationService.new.new_email(@email)
    else
      flash[:alert] = @email.errors.full_messages.first
    end

    redirect_to profile_emails_url
  end

  def destroy
    @email = current_user.emails.find(params[:id])
    @email.destroy

    current_user.update_secondary_emails!

    respond_to do |format|
      format.html { redirect_to profile_emails_url }
      format.js { render nothing: true }
    end
  end

  private

  def email_params
    params.require(:email).permit(:email)
  end
end
