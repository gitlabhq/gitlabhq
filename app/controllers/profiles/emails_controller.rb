class Profiles::EmailsController < Profiles::ApplicationController
  def index
    @primary = current_user.email
    @emails = current_user.emails
  end

  def create
    @email = Emails::CreateService.new(current_user, email_params).execute

    if @email.errors.blank?
      NotificationService.new.new_email(@email)
    else
      flash[:alert] = @email.errors.full_messages.first
    end

    redirect_to profile_emails_url
  end

  def destroy
    @email = current_user.emails.find(params[:id])

    Emails::DestroyService.new(current_user, email: @email.email).execute

    respond_to do |format|
      format.html { redirect_to profile_emails_url, status: 302 }
      format.js { head :ok }
    end
  end

  private

  def email_params
    params.require(:email).permit(:email)
  end
end
