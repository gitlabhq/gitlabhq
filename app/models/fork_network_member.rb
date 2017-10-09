class ForkNetworkMember < ActiveRecord::Base
  belongs_to :fork_network
  belongs_to :project
  belongs_to :forked_from_project, class_name: 'Project'

  validates :fork_network, :project, presence: true
end
