class ExternalIssue
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

  def ==(other)
    other.is_a?(self.class) && (to_s == other.to_s)
  end

  def project
    @project
  end
end
