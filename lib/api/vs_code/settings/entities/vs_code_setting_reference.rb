# frozen_string_literal: true

module API
  module VsCode
    module Settings
      module Entities
        class VsCodeSettingReference < Grape::Entity
          include ::API::Helpers::RelatedResourcesHelpers

          expose :url do |setting|
            resource_name = setting[:setting_type]
            id = setting[:uuid]
            path = "/api/v4/vscode/settings_sync/v1/resource/#{resource_name}/#{id}"
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
