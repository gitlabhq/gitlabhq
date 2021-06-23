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
                 desc: 'The visibility of the group'
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        optional :avatar, type: File, desc: 'Avatar image for the group' # rubocop:disable Scalability/FileUploads
        optional :share_with_group_lock, type: Boolean, desc: 'Prevent sharing a project with another group within this group'
        optional :require_two_factor_authentication, type: Boolean, desc: 'Require all users in this group to setup Two-factor authentication'
        optional :two_factor_grace_period, type: Integer, desc: 'Time before Two-factor authentication is enforced'
        optional :project_creation_level, type: String, values: ::Gitlab::Access.project_creation_string_values, desc: 'Determine if developers can create projects in the group', as: :project_creation_level_str
        optional :auto_devops_enabled, type: Boolean, desc: 'Default to Auto DevOps pipeline for all projects within this group'
        optional :subgroup_creation_level, type: String, values: ::Gitlab::Access.subgroup_creation_string_values, desc: 'Allowed to create subgroups', as: :subgroup_creation_level_str
        optional :emails_disabled, type: Boolean, desc: 'Disable email notifications'
        optional :mentions_disabled, type: Boolean, desc: 'Disable a group from getting mentioned'
        optional :lfs_enabled, type: Boolean, desc: 'Enable/disable LFS for the projects in this group'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :default_branch_protection, type: Integer, values: ::Gitlab::Access.protection_values, desc: 'Determine if developers can push to master'
        optional :shared_runners_setting, type: String, values: ::Namespace::SHARED_RUNNERS_SETTINGS, desc: 'Enable/disable shared runners for the group and its subgroups and projects'
      end

      params :optional_params_ee do
      end

      params :optional_update_params do
        optional :prevent_sharing_groups_outside_hierarchy, type: Boolean, desc: 'Prevent sharing groups within this namespace with any groups outside the namespace. Only available on top-level groups.'
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

API::Helpers::GroupsHelpers.prepend_mod_with('API::Helpers::GroupsHelpers')
