# frozen_string_literal: true

class Admin::SpamLogsController < Admin::ApplicationController
  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @spam_logs = SpamLog.order(id: :desc).page(params[:page])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    spam_log = SpamLog.find(params[:id])

    if params[:remove_user]
      spam_log.remove_user(deleted_by: current_user)
      redirect_to admin_spam_logs_path,
                  status: :found,
                  notice: _('User %{username} was successfully removed.') % { username: spam_log.user.username }
    else
      spam_log.destroy
      head :ok
    end
  end

  def mark_as_ham
    spam_log = SpamLog.find(params[:id])

    if HamService.new(spam_log).mark_as_ham!
      redirect_to admin_spam_logs_path, notice: _('Spam log successfully submitted as ham.')
    else
      redirect_to admin_spam_logs_path, alert: _('Error with Akismet. Please check the logs for more info.')
    end
  end
end
