# frozen_string_literal: true

module API
  module VsCode
    module Settings
      module Entities
        class VsCodeSettingReference < Grape::Entity
          include ::API::Helpers::RelatedResourcesHelpers

          expose :url do |setting|
            expose_path(api_v4_vscode_settings_sync_v1_resource_path(
              resource_name: setting[:setting_type],
              id: setting[:uuid]
            ))
          end
          expose :created do |setting|
            setting[:updated_at]&.to_i
          end
        end
      end
    end
  end
end
