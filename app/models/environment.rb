class Environment < ActiveRecord::Base
  belongs_to :project

  has_many :deployments

  validates_presence_of :name

  def last_deployment
    deployments.last
  end
end
