# frozen_string_literal: true

class GroupDeployKeyEntity < Grape::Entity
  expose :id
  expose :user_id
  expose :title
  expose :fingerprint
  expose :fingerprint_sha256
  expose :created_at
  expose :expires_at
  expose :updated_at
  expose :group_deploy_keys_groups, using: GroupDeployKeysGroupEntity do |group_deploy_key|
    group_deploy_key.group_deploy_keys_groups_for_user(options[:user])
  end
  expose :can_edit do |group_deploy_key|
    group_deploy_key.can_be_edited_for?(options[:user], options[:group])
  end
end
