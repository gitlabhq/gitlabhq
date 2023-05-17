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
    return :deploy_key if deploy_key.present?

    super
  end

  def humanize
    return "Deploy key" if deploy_key.present?

    super
  end

  def check_access(current_user)
    super do
      break enabled_deploy_key_for_user?(current_user) if deploy_key?
    end
  end

  private

  def deploy_key?
    type == :deploy_key
  end

  def validate_deploy_key_membership
    return unless deploy_key
    return if project.deploy_keys_projects.where(deploy_key: deploy_key).exists?

    errors.add(:deploy_key, 'is not enabled for this project')
  end

  def enabled_deploy_key_for_user?(current_user)
    current_user.can?(:read_project, project) &&
      deploy_key.user_id == current_user.id &&
      DeployKey.with_write_access_for_project(protected_tag.project, deploy_key: deploy_key).any?
  end
end
