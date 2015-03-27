# == Schema Information
#
# Table name: deploy_keys_projects
#
#  id            :integer          not null, primary key
#  deploy_key_id :integer          not null
#  project_id    :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class DeployKeysProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :deploy_key

  validates :deploy_key_id, presence: true
  validates :deploy_key_id, uniqueness: { scope: [:project_id], message: "already exists in project" }
  validates :project_id, presence: true

  after_destroy :destroy_orphaned_deploy_key

  private

  def destroy_orphaned_deploy_key
    # Public deploy keys are never automatically deleted
    return if self.deploy_key.public?
    return if self.deploy_key.deploy_keys_projects.length > 0

    self.deploy_key.destroy
  end
end
