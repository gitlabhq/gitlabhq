# frozen_string_literal: true

module API
  module VsCode
    module Settings
      module Entities
        class VsCodeSettingReference < Grape::Entity
          include ::API::Helpers::RelatedResourcesHelpers

          expose :url do |setting, options|
            resource_name = setting[:setting_type]
            id = setting[:uuid]

            # why: even though we're not storing settings_context_hash for non-extensions settings,
            # we still need to pass it as a route parameter as the Settings Sync client compares this URL with
            # settings sync URL passed in the configuration to provide remote sync activity items.
            settings_context_hash = options[:settings_context_hash]

            path = if settings_context_hash
                     "/api/v4/vscode/settings_sync/#{settings_context_hash}/v1/resource/#{resource_name}/#{id}"
                   else
                     "/api/v4/vscode/settings_sync/v1/resource/#{resource_name}/#{id}"
                   end

            expose_path(path)
          end
          expose :created do |setting|
            setting[:updated_at]&.to_i
          end
        end
      end
    end
  end
end
