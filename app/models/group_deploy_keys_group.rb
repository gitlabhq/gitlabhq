# frozen_string_literal: true

class GroupDeployKeysGroup < ApplicationRecord
  belongs_to :group, inverse_of: :group_deploy_keys_groups
  belongs_to :group_deploy_key, inverse_of: :group_deploy_keys_groups

  validates :group_deploy_key, presence: true
  validates :group_deploy_key_id, uniqueness: { scope: [:group_id], message: "already exists in group" }
  validates :group_id, presence: true
end
