class Admin::SpamLogsController < Admin::ApplicationController
  def index
    @spam_logs = SpamLog.order(id: :desc).page(params[:page])
  end

  def destroy
    spam_log = SpamLog.find(params[:id])

    if params[:remove_user]
      spam_log.remove_user
      redirect_to admin_spam_logs_path, notice: "User #{spam_log.user.username} was successfully removed."
    else
      spam_log.destroy
      render nothing: true
    end
  end
end
