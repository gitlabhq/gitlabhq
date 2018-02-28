class ForkNetworkMember < ActiveRecord::Base
  belongs_to :fork_network
  belongs_to :project
  belongs_to :forked_from_project, class_name: 'Project'

  validates :fork_network, :project, presence: true

  after_destroy :cleanup_fork_network

  private

  def cleanup_fork_network
    # Explicitly using `#count` makes sure we have the correct number if the
    # relation was loaded in the fork_network.
    fork_network.destroy if fork_network.fork_network_members.count == 0
  end
end
