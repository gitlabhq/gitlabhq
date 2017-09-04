class ProjectAutoDevops < ActiveRecord::Base
  belongs_to :project

  validates :domain, presence: true
end
