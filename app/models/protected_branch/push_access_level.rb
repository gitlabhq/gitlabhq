# frozen_string_literal: true

class ProtectedBranch::PushAccessLevel < ApplicationRecord
  include ProtectedBranchAccess
  include ProtectedRefDeployKeyAccess
  # default value for the access_level column
  GITLAB_DEFAULT_ACCESS_LEVEL = Gitlab::Access::MAINTAINER

  ignore_column :id_convert_to_bigint, remove_with: '18.3', remove_after: '2025-07-06'
  ignore_column :protected_branch_id_convert_to_bigint, remove_with: '18.3', remove_after: '2025-07-06'
  ignore_column :user_id_convert_to_bigint, remove_with: '18.3', remove_after: '2025-07-06'
  ignore_column :group_id_convert_to_bigint, remove_with: '18.3', remove_after: '2025-07-06'
  ignore_column :deploy_key_id_convert_to_bigint, remove_with: '18.3', remove_after: '2025-07-06'
end
