class Profiles::EmailsController < ApplicationController
  layout "profile"

  def index
    @primary = current_user.email
    @emails = current_user.emails
  end

  def create
    @email = current_user.emails.new(params[:email])
    
    flash[:alert] = @email.errors.full_messages.first unless @email.save

    redirect_to profile_emails_url
  end

  def destroy
    @email = current_user.emails.find(params[:id])
    @email.destroy

    respond_to do |format|
      format.html { redirect_to profile_emails_url }
      format.js { render nothing: true }
    end
  end
end
