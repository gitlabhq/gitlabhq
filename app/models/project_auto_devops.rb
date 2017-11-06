class ProjectAutoDevops < ActiveRecord::Base
  belongs_to :project

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  validates :domain, allow_blank: true, hostname: { allow_numeric_hostname: true }

  def has_domain?
    domain.present?
  end

  def variables
    variables = []
    variables << { key: 'AUTO_DEVOPS_DOMAIN', value: domain, public: true } if domain.present?
    variables
  end
end
