class DeployKey < Key
  has_many :deploy_keys_projects, dependent: :destroy
  has_many :projects, through: :deploy_keys_projects
end
