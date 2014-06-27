class GroupMilestone

  def initialize(title, milestones)
    @title = title
    @milestones = milestones
  end

  def title
    @title
  end

  def safe_title
    @title.gsub(".", "-")
  end

  def milestones
    @milestones
  end

  def projects
    milestones.map{ |milestone| milestone.project }
  end

  def issue_count
    milestones.map{ |milestone| milestone.issues.count }.sum
  end

  def merge_requests_count
    milestones.map{ |milestone| milestone.merge_requests.count }.sum
  end

  def open_items_count
    milestones.map{ |milestone| milestone.open_items_count }.sum
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

    if state.count('active') == state.size
      'active'
    else
      'closed'
    end
  end

  def active?
    state == 'active'
  end

  def closed?
    state == 'closed'
  end

  def opened_unassigned_issues
    milestones.map{ |milestone| milestone.issues.opened.unassigned }
  end

  def opened_assigned_issues
    milestones.map{ |milestone| milestone.issues.opened.assigned }
  end

  def closed_issues
    milestones.map{ |milestone| milestone.issues.closed }
  end

  def participants
    milestones.map{ |milestone| milestone.participants.uniq }.reject(&:empty?).flatten
  end

  def filter_by(filter, entity)
    if entity
      milestones = self.milestones.sort_by(&:project_id)
      entities = {}
      milestones.each do |project_milestone|
        next unless project_milestone.send(entity).any?
        project_name = project_milestone.project.name
        entities_by_state = state_filter(filter, project_milestone.send(entity))
        entities.store(project_name, entities_by_state)
      end
      entities
    else
      {}
    end
  end

  def state_filter(filter, entities)
    if entities.present?
      sorted_entities = entities.sort_by(&:position)
      entities_by_state =  case filter
                           when 'active'; sorted_entities.group_by(&:state)['opened']
                           when 'closed'; sorted_entities.group_by(&:state)['closed']
                           else sorted_entities
                           end
      if entities_by_state.blank?
        []
      else
        entities_by_state
      end
    else
      []
    end
  end

end
