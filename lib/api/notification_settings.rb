module API
  # notification_settings API
  class NotificationSettings < Grape::API
    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    resource :notification_settings do
      desc 'Get global notification level settings and email, defaults to Participate' do
        detail 'This feature was introduced in GitLab 8.12'
        success Entities::GlobalNotificationSetting
      end
      get do
        notification_setting = current_user.global_notification_setting

        present notification_setting, with: Entities::GlobalNotificationSetting
      end

      desc 'Update global notification level settings and email, defaults to Participate' do
        detail 'This feature was introduced in GitLab 8.12'
        success Entities::GlobalNotificationSetting
      end
      params do
        optional :level, type: String, desc: 'The global notification level'
        optional :notification_email, type: String, desc: 'The email address to send notifications'
        NotificationSetting::EMAIL_EVENTS.each do |event|
          optional event, type: Boolean, desc: 'Enable/disable this notification'
        end
      end
      put do
        notification_setting = current_user.global_notification_setting

        begin
          notification_setting.transaction do
            new_notification_email = params.delete(:notification_email)
            declared_params = declared(params, include_missing: false).to_h

            current_user.update(notification_email: new_notification_email) if new_notification_email
            notification_setting.update(declared_params)
          end
        rescue ArgumentError => e # catch level enum error
          render_api_error! e.to_s, 400
        end

        render_validation_error! current_user
        render_validation_error! notification_setting
        present notification_setting, with: Entities::GlobalNotificationSetting
      end
    end

    %w[group project].each do |source_type|
      resource source_type.pluralize do
        desc "Get #{source_type} level notification level settings, defaults to Global" do
          detail 'This feature was introduced in GitLab 8.12'
          success Entities::NotificationSetting
        end
        params do
          requires :id, type: String, desc: 'The group ID or project ID or project NAMESPACE/PROJECT_NAME'
        end
        get ":id/notification_settings" do
          source = find_source(source_type, params[:id])

          notification_setting = current_user.notification_settings_for(source)

          present notification_setting, with: Entities::NotificationSetting
        end

        desc "Update #{source_type} level notification level settings, defaults to Global" do
          detail 'This feature was introduced in GitLab 8.12'
          success Entities::NotificationSetting
        end
        params do
          requires :id, type: String, desc: 'The group ID or project ID or project NAMESPACE/PROJECT_NAME'
          optional :level, type: String, desc: "The #{source_type} notification level"
          NotificationSetting::EMAIL_EVENTS.each do |event|
            optional event, type: Boolean, desc: 'Enable/disable this notification'
          end
        end
        put ":id/notification_settings" do
          source = find_source(source_type, params.delete(:id))
          notification_setting = current_user.notification_settings_for(source)

          begin
            declared_params = declared(params, include_missing: false).to_h

            notification_setting.update(declared_params)
          rescue ArgumentError => e # catch level enum error
            render_api_error! e.to_s, 400
          end

          render_validation_error! notification_setting
          present notification_setting, with: Entities::NotificationSetting
        end
      end
    end
  end
end
