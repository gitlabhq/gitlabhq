# frozen_string_literal: true

module API
  module Entities
    class Group < BasicGroupDetails
      expose :path, :description, :visibility
      expose :share_with_group_lock
      expose :require_two_factor_authentication
      expose :two_factor_grace_period
      expose :project_creation_level_str, as: :project_creation_level
      expose :auto_devops_enabled
      expose :subgroup_creation_level_str, as: :subgroup_creation_level
      expose :emails_disabled
      expose :mentions_disabled
      expose :lfs_enabled?, as: :lfs_enabled
      expose :default_branch_protection
      expose :avatar_url do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :request_access_enabled
      expose :full_name, :full_path
      expose :created_at
      expose :parent_id

      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      expose :statistics, if: :statistics do
        with_options format_with: -> (value) { value.to_i } do
          expose :storage_size
          expose :repository_size
          expose :wiki_size
          expose :lfs_objects_size
          expose :build_artifacts_size, as: :job_artifacts_size
          expose :snippets_size
        end
      end
    end
  end
end

API::Entities::Group.prepend_mod_with('API::Entities::Group', with_descendants: true)
