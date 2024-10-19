# frozen_string_literal: true

module ProtectedRefDeployKeyAccess
  extend ActiveSupport::Concern

  included do
    belongs_to :deploy_key

    protected_ref_fk = "#{module_parent.model_name.singular}_id"
    validates :deploy_key_id, uniqueness: { scope: protected_ref_fk, allow_nil: true }
    validates :deploy_key, presence: true, if: :deploy_key_id
    validate :validate_deploy_key_owner_project_membership, if: :deploy_key
    validate :validate_deploy_key_project_access, if: :deploy_key
  end

  class_methods do
    def non_role_types
      super << :deploy_key
    end
  end

  def type
    return :deploy_key if deploy_key_id || deploy_key

    super
  end

  private

  def humanize_deploy_key
    deploy_key&.title || 'Deploy key'
  end

  def deploy_key?
    type == :deploy_key
  end

  def validate_deploy_key_owner_project_membership
    return if deploy_key_owner_project_member?

    errors.add(:deploy_key, 'owner is not a project member')
  end

  def validate_deploy_key_project_access
    return if deploy_key_has_write_access_to_project?

    errors.add(:deploy_key, 'is not enabled for this project')
  end

  # current_project is only available when evaluating a group-level protected
  # branch. We only allow role based access levels at the group-level so we can
  # ignore it here.
  def deploy_key_access_allowed?(current_user, _current_project)
    deploy_key_owned_by?(current_user) && valid_deploy_key_status?
  end

  def deploy_key_owned_by?(current_user)
    deploy_key.user_id == current_user.id
  end

  def valid_deploy_key_status?
    deploy_key.user.can?(:read_project, protected_ref_project) &&
      deploy_key_owner_project_member? &&
      deploy_key_has_write_access_to_project?
  end

  def deploy_key_owner_project_member?
    protected_ref_project.member?(deploy_key.user)
  end

  def deploy_key_has_write_access_to_project?
    DeployKey.with_write_access_for_project(protected_ref_project, deploy_key: deploy_key).exists?
  end
end
