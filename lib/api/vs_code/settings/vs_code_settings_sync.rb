# frozen_string_literal: true

module API
  module VsCode
    module Settings
      class VsCodeSettingsSync < ::API::Base
        include ::VsCode::Settings

        feature_category :web_ide
        urgency :low

        helpers do
          def find_settings
            return [DEFAULT_MACHINE] if params[:resource_name] == DEFAULT_MACHINE[:setting_type]

            SettingsFinder.new(current_user: current_user,
              setting_types: [params[:resource_name]],
              settings_context_hash: params[:settings_context_hash]).execute
          end
        end

        before do
          authenticate!

          header 'Access-Control-Expose-Headers', 'etag'
        end

        resource :vscode do
          resource '/settings_sync(/:settings_context_hash)' do
            content_type :json, 'application/json'
            content_type :json, 'text/plain'

            desc 'Get the settings manifest for Settings Sync' do
              success [Entities::VsCodeManifest]
              failure [
                { code: 401, message: '401 Unauthorized' }
              ]
              tags %w[vscode]
            end
            get '/v1/manifest' do
              settings = SettingsFinder.new(current_user: current_user,
                setting_types: SETTINGS_TYPES,
                settings_context_hash: params[:settings_context_hash]).execute
              presenter = VsCodeManifestPresenter.new(settings)

              present presenter, with: Entities::VsCodeManifest
            end

            desc 'Get a specific setting resource' do
              success [
                Entities::VsCodeSetting,
                { code: 204, message: 'No content' }
              ]
              failure [
                { code: 400, message: '400 bad request' },
                { code: 401, message: '401 Unauthorized' }
              ]
              tags %w[vscode]
            end
            params do
              requires :resource_name, type: String, desc: 'Name of the resource such as settings',
                values: SETTINGS_TYPES
              requires :id, type: String, desc: 'ID of the resource to retrieve'
            end
            get '/v1/resource/:resource_name/:id' do
              settings = find_settings

              if settings.blank?
                status :no_content
                header :etag, NO_CONTENT_ETAG
                body false
              else
                # This endpoint does not use the :id parameter
                # because the first iteration of this API only
                # supports storing a single record of a given setting_type.
                # We can rely on obtaining the first record of the setting
                # result.
                setting = settings.first
                header :etag, setting[:uuid]
                presenter = VsCodeSettingPresenter.new setting
                present presenter, with: Entities::VsCodeSetting
              end
            end

            desc 'Get a list of references to one or more vscode setting resources' do
              success [Entities::VsCodeSettingReference]
              failure [
                { code: 400, message: '400 bad request' },
                { code: 401, message: '401 Unauthorized' }
              ]
              tags %w[vscode]
            end
            params do
              requires :resource_name, type: String, desc: 'Name of the resource such as settings',
                values: SETTINGS_TYPES
            end
            get '/v1/resource/:resource_name' do
              settings = find_settings
              present settings, with: Entities::VsCodeSettingReference,
                settings_context_hash: params[:settings_context_hash]
            end

            desc 'Creates or updates a specific setting' do
              success [{ code: 200, message: 'OK' }]
              failure [
                { code: 400, message: 'Bad request' },
                { code: 401, message: '401 Unauthorized' }
              ]
            end
            params do
              requires :resource_name, type: String, desc: 'Name of the resource such as settings',
                values: SETTINGS_TYPES
            end
            post '/v1/resource/:resource_name' do
              response = CreateOrUpdateService.new(current_user: current_user,
                params: {
                  content: params[:content],
                  version: params[:version],
                  setting_type: params[:resource_name],
                  settings_context_hash: params[:settings_context_hash]
                }).execute

              if response.success?
                header 'Access-Control-Expose-Headers', 'etag'
                header 'Etag', response.payload[:uuid]
                present "OK"
              else
                error!(response.message, 400)
              end
            end

            desc 'Deletes all user vscode setting resources' do
              success [{ code: 200, message: 'OK' }]
              failure [
                { code: 401, message: '401 Unauthorized' }
              ]
              tags %w[vscode]
            end
            delete '/v1/collection' do
              DeleteService.new(current_user: current_user).execute

              present "OK"
            end
          end
        end
      end
    end
  end
end
