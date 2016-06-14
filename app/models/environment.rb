class Environment < ActiveRecord::Base
  belongs_to :project

  has_many :deployments

  validates :name,
            presence: true,
            length: { within: 0..255 },
            format: { with: Gitlab::Regex.environment_name_regex,
                      message: Gitlab::Regex.environment_name_regex_message }

  validates_uniqueness_of :name, scope: :project_id

  validates_associated :project

  def last_deployment
    deployments.last
  end
end
