# frozen_string_literal: true

class ProtectedBranch::PushAccessLevel < ApplicationRecord
  include ProtectedBranchAccess

  belongs_to :deploy_key

  validates :access_level, uniqueness: { scope: :protected_branch_id, if: :role?,
                                         conditions: -> { where(user_id: nil, group_id: nil, deploy_key_id: nil) } }
  validates :deploy_key_id, uniqueness: { scope: :protected_branch_id, allow_nil: true }
  validate :validate_deploy_key_membership

  def type
    if self.deploy_key.present?
      :deploy_key
    else
      super
    end
  end

  private

  def validate_deploy_key_membership
    return unless deploy_key

    unless project.deploy_keys_projects.where(deploy_key: deploy_key).exists?
      self.errors.add(:deploy_key, 'is not enabled for this project')
    end
  end
end
