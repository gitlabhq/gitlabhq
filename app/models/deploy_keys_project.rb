class DeployKeysProject < ActiveRecord::Base
  attr_accessible :key_id, :project_id

  belongs_to :project
  belongs_to :deploy_key

  validates :deploy_key_id, presence: true
  validates :deploy_key_id, uniqueness: { scope: [:project_id], message: "already exists in project" }

  validates :project_id, presence: true
end
