class ProjectAutoDevops < ActiveRecord::Base
  belongs_to :project

  validates :domain, presence: true, hostname: { allow_numeric_hostname: true }, if: :enabled?
end
