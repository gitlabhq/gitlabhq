class GlobalMilestone
  include Milestoneish

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
    @issues ||= Issue.of_milestones(milestones.map(&:id)).includes(:project)
  end

  def merge_requests
    @merge_requests ||= MergeRequest.of_milestones(milestones.map(&:id)).includes(:target_project)
  end

  def participants
    @participants ||= milestones.map(&:participants).flatten.compact.uniq
  end

  def labels
    @labels ||= GlobalLabel.build_collection(milestones.map(&:labels).flatten)
                           .sort_by!(&:title)
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
