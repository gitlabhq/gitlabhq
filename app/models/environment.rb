class Environment < ActiveRecord::Base
  belongs_to :project, required: true, validate: true

  has_many :deployments

  validates :name,
            presence: true,
            uniqueness: { scope: :project_id },
            length: { within: 0..255 },
            format: { with: Gitlab::Regex.environment_name_regex,
                      message: Gitlab::Regex.environment_name_regex_message }

  def last_deployment
    deployments.last
  end
end
