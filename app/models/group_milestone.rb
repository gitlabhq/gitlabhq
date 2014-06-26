class GroupMilestone

  def initialize(title, milestones)
    @title = title
    @milestones = milestones
  end

  def title
    @title
  end

  def milestones
    @milestones
  end

  def project_names
    milestones.map{ |milestone| milestone.project.name }
  end

  def issue_count
    milestones.map{ |milestone| milestone.issues.count }.sum
  end

  def merge_requests_count
    milestones.map{ |milestone| milestone.merge_requests.count }.sum
  end

  def closed_items_count
    milestones.map{ |milestone| milestone.closed_items_count }.sum
  end

  def total_items_count
    milestones.map{ |milestone| milestone.total_items_count }.sum
  end

  def percent_complete
    ((closed_items_count * 100) / total_items_count).abs
  rescue ZeroDivisionError
    100
  end

  def state
    state = milestones.map{ |milestone| milestone.state }
    if state.all?{ |milestone_state| milestone_state == 'active' }
      'active'
    else
      'closed'
    end
  end
end
