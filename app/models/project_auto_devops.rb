class ProjectAutoDevops < ActiveRecord::Base
  belongs_to :project

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  validates :domain, allow_blank: true, hostname: { allow_numeric_hostname: true }

  def instance_domain
    Gitlab::CurrentSettings.auto_devops_domain
  end

  def has_domain?
    domain.present? || instance_domain.present?
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      if has_domain?
        variables.append(key: 'AUTO_DEVOPS_DOMAIN',
                         value: domain.presence || instance_domain)
      end
    end
  end
end
