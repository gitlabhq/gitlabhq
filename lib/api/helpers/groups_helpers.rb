# frozen_string_literal: true

module API
  module Helpers
    module GroupsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ce do
        optional :description, type: String, desc: 'The description of the group'
        optional :visibility, type: String,
                 values: Gitlab::VisibilityLevel.string_values,
                 default: Gitlab::VisibilityLevel.string_level(
                   Gitlab::CurrentSettings.current_application_settings.default_group_visibility),
                 desc: 'The visibility of the group'
        optional :lfs_enabled, type: Boolean, desc: 'Enable/disable LFS for the projects in this group'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :share_with_group_lock, type: Boolean, desc: 'Prevent sharing a project with another group within this group'
      end

      params :optional_params_ee do
      end

      params :optional_update_params_ee do
      end

      params :optional_params do
        use :optional_params_ce
        use :optional_params_ee
      end

      params :optional_projects_params_ee do
      end

      params :optional_projects_params do
        use :optional_projects_params_ee
      end
    end
  end
end
