class Admin::SpamLogsController < Admin::ApplicationController
  include Gitlab::AkismetHelper

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
      head :ok
    end
  end

  def mark_as_ham
    spam_log = SpamLog.find(params[:id])

    if ham!(spam_log.source_ip, spam_log.user_agent, spam_log.text, spam_log.user)
      spam_log.update_attribute(:submitted_as_ham, true)
      redirect_to admin_spam_logs_path, notice: 'Spam log successfully submitted as ham.'
    else
      redirect_to admin_spam_logs_path, notice: 'Error with Akismet. Please check the logs for more info.'
    end
  end
end
