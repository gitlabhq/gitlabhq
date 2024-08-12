# frozen_string_literal: true

class Admin::SpamLogsController < Admin::ApplicationController
  feature_category :instance_resiliency

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @spam_logs = SpamLog.preload(user: [:trusted_with_spam_attribute])
      .order(id: :desc)
      .page(pagination_params[:page]).without_count
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    spam_log = SpamLog.find(safe_params[:id])

    if safe_params[:remove_user]
      spam_log.remove_user(deleted_by: current_user)
      redirect_to admin_spam_logs_path,
        status: :found,
        notice: format(_('User %{username} was successfully removed.'), username: spam_log.user.username)
    else
      spam_log.destroy
      head :ok
    end
  end

  def mark_as_ham
    spam_log = SpamLog.find(safe_params[:id])

    if Spam::HamService.new(spam_log).execute
      redirect_to admin_spam_logs_path, notice: _('Spam log successfully submitted as ham.')
    else
      redirect_to admin_spam_logs_path, alert: _('Error with Akismet. Please check the logs for more info.')
    end
  end

  private

  def safe_params
    params.permit(:id, :remove_user)
  end
end
