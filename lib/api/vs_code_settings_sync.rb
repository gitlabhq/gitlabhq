# frozen_string_literal: true

module API
  class VsCodeSettingsSync < ::API::Base
    feature_category :web_ide

    resource :vscode do
      resource :settings_sync do
        content_type :json, 'application/json'
        content_type :json, 'text/plain'

        desc 'Get the settings manifest for Settings Sync' do
          success Entities::VsCodeManifest
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags %w[vscode]
        end
        get '/v1/manifest' do
          authenticate!

          type_list = %w[settings extensions]

          settings = ::VsCode::SettingsFinder.new(current_user, type_list).execute

          latest_settings_map = settings.each_with_object({}) do |setting, hash|
            hash[setting.setting_type] = setting.id
          end

          header 'Access-Control-Expose-Headers', 'etag'
          result = {
            latest: latest_settings_map,
            session: "1"
          }
          present result, with: Entities::VsCodeManifest
        end

        desc 'Get the list of machines'
        get '/v1/resource/machines/latest' do
          authenticate!
          header 'Access-Control-Expose-Headers', 'etag'
          {
            version: 1,
            machines: [
              {
                id: 1,
                name: "GitLab WebIDE",
                platform: "GitLab"
              }
            ]
          }
        end

        desc 'Get a specific setting resource'
        params do
          requires :resource_name, type: String, desc: 'Name of the resource such as settings'
          requires :id, type: String, desc: 'ID of the resource to retrieve'
        end
        get '/v1/resource/:resource_name/:id' do
          authenticate!
          header 'Access-Control-Expose-Headers', 'etag'
          result = {
            version: 1,
            content: "{}",
            machineId: "1"
          }

          setting_name = params[:resource_name]
          settings = ::VsCode::SettingsFinder.new(current_user, [setting_name]).execute

          result[:content] = settings.first[:content] if settings.present?
          present result
        end

        desc 'Update a specific setting'
        params do
          requires :resource_name, type: String, desc: 'Name of the resource such as settings'
        end
        post '/v1/resource/:resource_name' do
          authenticate!
          response = ::VsCode::Settings::CreateOrUpdateService.new(current_user: current_user, params: {
            content: params[:content],
            setting_type: params[:resource_name]
          }).execute

          if response.success?
            header 'Access-Control-Expose-Headers', 'etag'
            header 'Etag', response.payload.id
            present "OK"
          else
            error!(response.message, 400)
          end
        end
      end
    end
  end
end
