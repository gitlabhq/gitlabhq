class ProjectAutoDevops < ApplicationRecord
  belongs_to :project

  validates :domain, allow_blank: true, hostname: { allow_numeric_hostname: true }

  def variables
    variables = []
    variables << { key: 'AUTO_DEVOPS_DOMAIN', value: domain, public: true } if domain.present?
    variables
  end
end
