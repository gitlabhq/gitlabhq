class ProjectDeployToken < ActiveRecord::Base
  belongs_to :project
  belongs_to :deploy_token, inverse_of: :project_deploy_tokens

  validates :deploy_token, presence: true
  validates :project, presence: true
  validates :deploy_token_id, uniqueness: { scope: [:project_id] }

  accepts_nested_attributes_for :deploy_token

  def redis_shared_state_key(user_id)
    "gitlab:deploy_token:#{project_id}:#{user_id}"
  end
end
