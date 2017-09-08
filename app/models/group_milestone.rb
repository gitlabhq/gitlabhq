class GroupMilestone < GlobalMilestone
  attr_accessor :group

  def self.build_collection(group, projects, params)
    super(projects, params).each do |milestone|
      milestone.group = group
    end
  end

  def self.build(group, projects, title)
    super(projects, title).tap do |milestone|
      milestone&.group = group
    end
  end

  def issues_finder_params
    { group_id: group.id }
  end

  def legacy_group_milestone?
    true
  end
end
