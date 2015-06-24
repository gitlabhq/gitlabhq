# NoMilestone
#
# Represents a "No Milestone" state used for filtering Issues and Merge Requests
# that have no milestone assigned.
class NoMilestone
  def self.id
    nil
  end

  def self.title
    'No Milestone'
  end
end
