# frozen_string_literal: true

module API
  # notification_settings API
  class NotificationSettings < ::API::Base
    before { authenticate! }

    feature_category :team_planning
    urgency :low

    helpers ::API::Helpers::MembersHelpers

    resource :notification_settings do
      desc 'Retrieve global notification settings' do
        detail 'Retrieves the global notification level and email address.'
        success Entities::GlobalNotificationSetting
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
        tags ['notification_settings']
      end
      route_setting :authorization, permissions: :read_notification_setting, boundary_type: :user
      get do
        notification_setting = current_user.global_notification_setting

        present notification_setting, with: Entities::GlobalNotificationSetting
      end

      desc 'Update global notification settings' do
        detail 'Updates notification settings and email address.'
        success Entities::GlobalNotificationSetting
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags ['notification_settings']
      end
      params do
        optional :level, type: String, desc: 'The global notification level'
        optional :notification_email, type: String, desc: 'The email address to send notifications'
        NotificationSetting.email_events.each do |event|
          optional event, type: Boolean, desc: 'Enable/disable this notification'
        end
      end
      route_setting :authorization, permissions: :update_notification_setting, boundary_type: :user
      put do
        notification_setting = current_user.global_notification_setting

        begin
          notification_setting.transaction do
            new_notification_email = params.delete(:notification_email)

            Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
              %w[users user_details], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424289'
            ) do
              if new_notification_email
                ::Users::UpdateService.new(current_user, user: current_user, notification_email: new_notification_email).execute
              end
            end

            notification_setting.update(declared_params(include_missing: false))
          end
        rescue ArgumentError => e # catch level enum error
          render_api_error! e.to_s, 400
        end

        render_validation_error! current_user
        render_validation_error! notification_setting
        present notification_setting, with: Entities::GlobalNotificationSetting
      end
    end

    [Group, Project].each do |source_class|
      source_type = source_class.name.underscore

      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Retrieve notification settings for a #{source_type}" do
          detail "Retrieves the notification level for a specified #{source_type}."
          success Entities::NotificationSetting
          failure [
            { code: 401, message: 'Unauthorized' }
          ]
          tags ['notification_settings']
        end
        route_setting :authorization, permissions: :read_notification_setting, boundary_type: :user
        get ":id/notification_settings" do
          source = find_source(source_type, params[:id])

          notification_setting = current_user.notification_settings_for(source)

          present notification_setting, with: Entities::NotificationSetting
        end

        desc "Update notification settings for a #{source_type}" do
          detail "Updates the notification settings for a specified #{source_type}."
          success Entities::NotificationSetting
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' }
          ]
          tags ['notification_settings']
        end
        params do
          optional :level, type: String, desc: "The #{source_type} notification level"
          NotificationSetting.email_events(source_class).each do |event|
            optional event, type: Boolean, desc: 'Enable/disable this notification'
          end
        end
        route_setting :authorization, permissions: :update_notification_setting, boundary_type: :user
        put ":id/notification_settings" do
          source = find_source(source_type, params.delete(:id))
          notification_setting = current_user.notification_settings_for(source)

          begin
            notification_setting.update(declared_params(include_missing: false))
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
