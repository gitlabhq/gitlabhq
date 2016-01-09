class Admin::SpamLogsController < Admin::ApplicationController
  before_action :set_spam_log, only: [:destroy]

  def index
    @spam_logs = SpamLog.order(created_at: :desc).page(params[:page])
  end

  def destroy
    @spam_log.destroy
    message = 'Spam log was successfully destroyed.'

    if params[:remove_user]
      username = @spam_log.user.username
      @spam_log.user.destroy
      message = "User #{username} was successfully destroyed."
    end

    respond_to do |format|
      format.json { render json: '{}' }
      format.html { redirect_to admin_spam_logs_path, notice: message }
    end
  end

  private

  def set_spam_log
    @spam_log = SpamLog.find(params[:id])
  end

  def spam_log_params
    params[:spam_log]
  end
end
