# frozen_string_literal: true

class Profiles::NotificationsController < Profiles::ApplicationController
  feature_category :team_planning
  urgency :low

  def show
    @user = current_user
    @user_groups = user_groups
    @group_notifications = UserGroupNotificationSettingsFinder.new(current_user, user_groups).execute
    @project_notifications = project_notifications_with_preloaded_associations
    @global_notification_setting = current_user.global_notification_setting
  end

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

  private

  def user_groups
    GroupsFinder.new(current_user, all_available: false).execute.order_name_asc.page(pagination_params[:page])
  end

  def project_notifications_with_preloaded_associations
    project_notifications = current_user
      .notification_settings
      .for_projects
      .order_by_id_asc
      .preload_source_route

    projects = project_notifications.map(&:source)
    ActiveRecord::Associations::Preloader.new(
      records: projects,
      associations: project_associations
    ).call
    Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute

    project_notifications.select { |notification| current_user.can?(:read_project, notification.source) }
  end

  def project_associations
    { namespace: [:route, :owner], group: [], creator: [], project_setting: [] }
  end
end

Profiles::NotificationsController.prepend_mod
