# frozen_string_literal: true

class ProtectedTag::CreateAccessLevel < ApplicationRecord
  include Importable
  include ProtectedTagAccess

  belongs_to :deploy_key

  validates :access_level, uniqueness: { scope: :protected_tag_id, if: :role?,
                                         conditions: -> { where(user_id: nil, group_id: nil, deploy_key_id: nil) } }
  validates :deploy_key_id, uniqueness: { scope: :protected_tag_id, allow_nil: true }
  validate :validate_deploy_key_membership

  def type
    if deploy_key.present?
      :deploy_key
    else
      super
    end
  end

  def humanize
    return "Deploy key" if deploy_key.present?

    super
  end

  def check_access(user)
    return false if access_level == Gitlab::Access::NO_ACCESS

    if user && deploy_key.present?
      return user.can?(:read_project, project) && enabled_deploy_key_for_user?(deploy_key, user)
    end

    super
  end

  private

  def validate_deploy_key_membership
    return unless deploy_key

    return if project.deploy_keys_projects.where(deploy_key: deploy_key).exists?

    errors.add(:deploy_key, 'is not enabled for this project')
  end

  def enabled_deploy_key_for_user?(deploy_key, user)
    deploy_key.user_id == user.id &&
      DeployKey.with_write_access_for_project(protected_tag.project, deploy_key: deploy_key).any?
  end
end
