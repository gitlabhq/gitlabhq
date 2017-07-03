class ExternalIssue
  include Referable

  def initialize(issue_identifier, project)
    @issue_identifier, @project = issue_identifier, project
  end

  def to_s
    @issue_identifier.to_s
  end

  def id
    @issue_identifier.to_s
  end

  def iid
    @issue_identifier.to_s
  end

  def title
    "External Issue #{self}"
  end

  def ==(other)
    other.is_a?(self.class) && (to_s == other.to_s)
  end
  alias_method :eql?, :==

  def hash
    [self.class, to_s].hash
  end

  def project
    @project
  end

  def project_id
    @project.id
  end

  def to_reference(_from_project = nil, full: nil)
    id
  end

  def reference_link_text(from_project = nil)
    return "##{id}" if id =~ /^\d+$/

    id
  end
end
