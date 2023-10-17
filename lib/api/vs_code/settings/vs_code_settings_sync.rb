# frozen_string_literal: true

module API
  module VsCode
    module Settings
      class VsCodeSettingsSync < ::API::Base
        include ::VsCode::Settings

        feature_category :web_ide

        before do
          authenticate!

          header 'Access-Control-Expose-Headers', 'etag'
        end

        resource :vscode do
          resource :settings_sync do
            content_type :json, 'application/json'
            content_type :json, 'text/plain'

            desc 'Get the settings manifest for Settings Sync' do
              success [Entities::VsCodeManifest]
              tags %w[vscode]
            end
            get '/v1/manifest' do
              settings = SettingsFinder.new(current_user, SETTINGS_TYPES).execute
              presenter = VsCodeManifestPresenter.new(settings)

              present presenter, with: Entities::VsCodeManifest
            end

            desc 'Get a specific setting resource' do
              success [Entities::VsCodeSetting]
              tags %w[vscode]
            end
            params do
              requires :resource_name, type: String, desc: 'Name of the resource such as settings'
              requires :id, type: String, desc: 'ID of the resource to retrieve'
            end
            get '/v1/resource/:resource_name/:id' do
              authenticate!

              setting_name = params[:resource_name]
              setting = nil

              if params[:resource_name] == 'machines'
                setting = DEFAULT_MACHINE
              else
                settings = SettingsFinder.new(current_user, [setting_name]).execute
                setting = settings.first if settings.present?
              end

              if setting.nil?
                status :no_content
                header :etag, NO_CONTENT_ETAG
                body false
              else
                header :etag, setting[:uuid]
                presenter = VsCodeSettingPresenter.new setting
                present presenter, with: Entities::VsCodeSetting
              end
            end

            desc 'Update a specific setting'
            params do
              requires :resource_name, type: String, desc: 'Name of the resource such as settings'
            end
            post '/v1/resource/:resource_name' do
              authenticate!

              response = CreateOrUpdateService.new(current_user: current_user, params: {
                content: params[:content],
                version: params[:version],
                setting_type: params[:resource_name]
              }).execute

              if response.success?
                header 'Access-Control-Expose-Headers', 'etag'
                header 'Etag', response.payload[:uuid]
                present "OK"
              else
                error!(response.message, 400)
              end
            end
          end
        end
      end
    end
  end
end
