# frozen_string_literal: true

class Profiles::NotificationsController < Profiles::ApplicationController
  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @user = current_user
    @group_notifications = current_user.notification_settings.for_groups.order(:id)
    @group_notifications += GroupsFinder.new(
      current_user,
      all_available: false,
      exclude_group_ids: @group_notifications.select(:source_id)
    ).execute.map { |group| current_user.notification_settings_for(group, inherit: true) }
    @project_notifications = current_user.notification_settings.for_projects.order(:id)
                             .select { |notification| current_user.can?(:read_project, notification.source) }
    @global_notification_setting = current_user.global_notification_setting
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def update
    result = Users::UpdateService.new(current_user, user_params.merge(user: current_user)).execute

    if result[:status] == :success
      flash[:notice] = _("Notification settings saved")
    else
      flash[:alert] = _("Failed to save new settings")
    end

    redirect_back_or_default(default: profile_notifications_path)
  end

  def user_params
    params.require(:user).permit(:notification_email, :notified_of_own_activity)
  end
end
