# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#

class DeployKey < Key
  has_many :deploy_keys_projects, dependent: :destroy
  has_many :projects, through: :deploy_keys_projects

  scope :in_projects, ->(projects) { joins(:deploy_keys_projects).where('deploy_keys_projects.project_id in (?)', projects) }
end
