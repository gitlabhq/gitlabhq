class Projects::NotificationSettingsController < Projects::ApplicationController
  before_action :authenticate_user!

  def update
    @notification_setting = current_user.notification_settings_for(project)

    if params[:custom_events].nil?
      saved = @notification_setting.update_attributes(notification_setting_params)
    else
      events = params[:events] || {}

      NotificationSetting::EMAIL_EVENTS.each do |event|
        @notification_setting.events[event] = events[event]
      end

      saved = @notification_setting.save
    end

    render json: {
      html: view_to_html_string("projects/buttons/_notifications", locals: { project: @project, notification_setting: @notification_setting }),
      saved: saved,
    }
  end

  private

  def notification_setting_params
    params.require(:notification_setting).permit(:level)
  end
end
