class TokenResource < ActiveRecord::Base
  belongs_to :personal_access_token
  belongs_to :project

  validates :personal_access_token, presence: true
  validates :project, presence: true

  def self.allowing_resource(resource)
    where(project: resource)
  end
end
