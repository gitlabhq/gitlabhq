class ProjectAutoDevops < ActiveRecord::Base
  belongs_to :project

  validates :domain, presence: true, hostname: { allow_numeric_hostname: true }, if: :enabled?

  def variables
    variables = []
    variables << { key: 'AUTO_DEVOPS_DOMAIN', value: domain, public: true } if domain.present?
    variables
  end
end
