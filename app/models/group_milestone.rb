class GroupMilestone

  def initialize(title, milestones)
    @title = title
    @milestones = milestones
  end

  def title
    @title
  end

  def safe_title
    @title.parameterize
  end

  def milestones
    @milestones
  end

  def projects
    milestones.map { |milestone| milestone.project }
  end

  def issue_count
    milestones.map { |milestone| milestone.issues.count }.sum
  end

  def merge_requests_count
    milestones.map { |milestone| milestone.merge_requests.count }.sum
  end

  def open_items_count
    milestones.map { |milestone| milestone.open_items_count }.sum
  end

  def closed_items_count
    milestones.map { |milestone| milestone.closed_items_count }.sum
  end

  def total_items_count
    milestones.map { |milestone| milestone.total_items_count }.sum
  end

  def percent_complete
    ((closed_items_count * 100) / total_items_count).abs
  rescue ZeroDivisionError
    100
  end

  def state
    state = milestones.map { |milestone| milestone.state }

    if state.count('closed') == state.size
      'closed'
    else
      'active'
    end
  end

  def active?
    state == 'active'
  end

  def closed?
    state == 'closed'
  end

  def issues
    @group_issues ||= milestones.map { |milestone| milestone.issues }.flatten.group_by(&:state)
  end

  def merge_requests
    @group_merge_requests ||= milestones.map { |milestone| milestone.merge_requests }.flatten.group_by(&:state)
  end

  def participants
    milestones.map { |milestone| milestone.participants.uniq }.reject(&:empty?).flatten
  end

  def opened_issues
    issues.values_at("opened", "reopened").compact.flatten
  end

  def closed_issues
    issues['closed']
  end

  def opened_merge_requests
    merge_requests.values_at("opened", "reopened").compact.flatten
  end

  def closed_merge_requests
    merge_requests.values_at("closed", "merged", "locked").compact.flatten
  end
end
