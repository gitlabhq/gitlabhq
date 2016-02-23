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
    @projects ||= Project.for_milestones(milestones.map(&:id))
  end

  def issues_count
    issues.count
  end

  def merge_requests_count
    merge_requests.count
  end

  def open_items_count
    opened_issues.count + opened_merge_requests.count
  end

  def closed_items_count
    closed_issues.count + closed_merge_requests.count
  end

  def total_items_count
    issues_count + merge_requests_count
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
    @issues ||= Issue.of_milestones(milestones.map(&:id))
  end

  def merge_requests
    @merge_requests ||= MergeRequest.of_milestones(milestones.map(&:id))
  end

  def participants
    @participants ||= milestones.map(&:participants).flatten.compact.uniq
  end

  def opened_issues
    issues.opened
  end

  def closed_issues
    issues.closed
  end

  def opened_merge_requests
    merge_requests.opened
  end

  def closed_merge_requests
    merge_requests.with_states(:closed, :merged, :locked)
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
