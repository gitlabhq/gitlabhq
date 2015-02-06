class Admin::EmailsController < Admin::ApplicationController
  def show
  end

  def create
    AdminEmailsWorker.perform_async(params[:recipients], params[:subject], params[:body])
    redirect_to admin_email_path, notice: 'Email sent'
  end
end
