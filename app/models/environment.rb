class Environment < ActiveRecord::Base
  belongs_to :project, required: true, validate: true

  has_many :deployments

  before_validation :nullify_external_url

  validates :name,
            presence: true,
            uniqueness: { scope: :project_id },
            length: { within: 0..255 },
            format: { with: Gitlab::Regex.environment_name_regex,
                      message: Gitlab::Regex.environment_name_regex_message }

  validates :external_url,
            uniqueness: { scope: :project_id },
            length: { maximum: 255 },
            allow_nil: true,
            addressable_url: true

  def last_deployment
    deployments.last
  end

  def nullify_external_url
    self.external_url = nil if self.external_url.blank?
  end

  def includes_commit?(commit)
    return false unless last_deployment

    last_deployment.includes_commit?(commit)
  end
end
