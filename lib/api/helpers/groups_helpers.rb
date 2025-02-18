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
        optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for the group', documentation: { type: 'file' }
        optional :share_with_group_lock, type: Boolean, desc: 'Prevent sharing a project with another group within this group'
        optional :require_two_factor_authentication, type: Boolean, desc: 'Require all users in this group to setup Two-factor authentication'
        optional :two_factor_grace_period, type: Integer, desc: 'Time before Two-factor authentication is enforced'
        optional :project_creation_level, type: String, values: ::Gitlab::Access.project_creation_string_values, desc: 'Determine if developers can create projects in the group', as: :project_creation_level_str
        optional :auto_devops_enabled, type: Boolean, desc: 'Default to Auto DevOps pipeline for all projects within this group'
        optional :subgroup_creation_level, type: String, values: ::Gitlab::Access.subgroup_creation_string_values, desc: 'Allowed to create subgroups', as: :subgroup_creation_level_str
        optional :emails_disabled, type: Boolean, desc: '_(Deprecated)_ Disable email notifications. Use: emails_enabled'
        optional :emails_enabled, type: Boolean, desc: 'Enable email notifications'
        optional :show_diff_preview_in_email, type: Boolean, desc: 'Include the code diff preview in merge request notification emails'
        optional :mentions_disabled, type: Boolean, desc: 'Disable a group from getting mentioned'
        optional :lfs_enabled, type: Boolean, desc: 'Enable/disable LFS for the projects in this group'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :default_branch, type: String, desc: "The default branch of group's projects", documentation: { example: 'main' }, as: :default_branch_name
        optional :default_branch_protection, type: Integer, values: ::Gitlab::Access.protection_values, desc: 'Determine if developers can push to default branch'
        optional :default_branch_protection_defaults, type: Hash, desc: 'Determine if developers can push to default branch' do
          optional :allowed_to_push, type: Array, desc: 'An array of access levels allowed to push' do
            requires :access_level, type: Integer, values: ProtectedBranch::PushAccessLevel.allowed_access_levels, desc: 'A valid access level'
          end
          optional :allow_force_push, type: Boolean, desc: 'Allow force push for all users with push access.'
          optional :allowed_to_merge, type: Array, desc: 'An array of access levels allowed to merge' do
            requires :access_level, type: Integer, values: ProtectedBranch::MergeAccessLevel.allowed_access_levels, desc: 'A valid access level'
          end
          optional :code_owner_approval_required, type: Boolean, desc: "Require approval from code owners"
          optional :developer_can_initial_push, type: Boolean, desc: 'Allow developers to initial push'
        end
        optional :shared_runners_setting, type: String, values: ::Namespace::SHARED_RUNNERS_SETTINGS, desc: 'Enable/disable shared runners for the group and its subgroups and projects'
        optional :enabled_git_access_protocol, type: String, values: %w[ssh http all], desc: 'Allow only the selected protocols to be used for Git access.'
      end

      params :optional_params_ee do
      end

      params :optional_update_params do
        optional :prevent_sharing_groups_outside_hierarchy, type: Boolean, desc: 'Prevent sharing groups within this namespace with any groups outside the namespace. Only available on top-level groups.'
        optional :lock_math_rendering_limits_enabled, type: Boolean, desc: 'Indicates if math rendering limits are locked for all descendent groups.'
        optional :math_rendering_limits_enabled, type: Boolean, desc: 'Indicates if math rendering limits are used for this group.'
        optional :max_artifacts_size, type: Integer, desc: "Set the maximum file size for each job's artifacts"
      end

      params :optional_update_params_ee do
      end

      params :optional_params do
        use :optional_params_ce
        use :optional_params_ee
      end

      params :optional_projects_params_ee do
      end

      params :optional_group_list_params_ee do
      end

      params :optional_projects_params do
        use :optional_projects_params_ee
      end
    end
  end
end

API::Helpers::GroupsHelpers.prepend_mod_with('API::Helpers::GroupsHelpers')
