# frozen_string_literal: true

class DeployKeysProject < ApplicationRecord
  belongs_to :project, inverse_of: :deploy_keys_projects
  belongs_to :deploy_key, inverse_of: :deploy_keys_projects
  scope :in_project, ->(project) { where(project: project) }
  scope :with_write_access, -> { where(can_push: true) }
  scope :with_readonly_access, -> { where(can_push: false) }

  accepts_nested_attributes_for :deploy_key

  validates :deploy_key, presence: true
  validates :deploy_key_id, uniqueness: { scope: [:project_id], message: "already exists in project" }
  validates :project_id, presence: true

  after_destroy :destroy_orphaned_deploy_key

  private

  def destroy_orphaned_deploy_key
    return unless self.deploy_key.destroyed_when_orphaned? && self.deploy_key.orphaned?

    self.deploy_key.destroy
  end
end
