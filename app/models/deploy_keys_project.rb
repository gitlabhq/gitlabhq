class DeployKeysProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :deploy_key, inverse_of: :deploy_keys_projects

  scope :without_project_deleted,  -> { joins(:project).where(projects: { pending_delete: false }) }
  scope :in_project, ->(project) { where(project: project) }
  scope :with_write_access, -> { where(can_push: true) }

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
