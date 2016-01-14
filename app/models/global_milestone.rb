class GlobalMilestone
  attr_accessor :title, :milestones
  alias_attribute :name, :title

  def self.build_collection(milestones)
    milestones = milestones.group_by(&:title)

    milestones.map do |title, milestones|
      new(title, milestones)
    end
  end

  def initialize(title, milestones)
    @title = title
    @milestones = milestones
  end

  def safe_title
    @title.to_slug.normalize.to_s
  end

  def expired?
    if due_date
      due_date.past?
    else
      false
    end
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
    0
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
    @issues ||= milestones.map(&:issues).flatten.group_by(&:state)
  end

  def merge_requests
    @merge_requests ||= milestones.map(&:merge_requests).flatten.group_by(&:state)
  end

  def participants
    @participants ||= milestones.map(&:participants).flatten.compact.uniq
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

  def complete?
    total_items_count == closed_items_count
  end

  def due_date
    return @due_date if defined?(@due_date)

    @due_date =
      if @milestones.all? { |x| x.due_date == @milestones.first.due_date }
        @milestones.first.due_date
      else
        nil
      end
  end

  def expires_at
    if due_date
      if due_date.past?
        "expired on #{due_date.to_s(:medium)}"
      else
        "expires on #{due_date.to_s(:medium)}"
      end
    end
  end
end
