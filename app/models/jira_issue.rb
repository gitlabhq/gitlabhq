class JiraIssue
  def initialize(issue_identifier)
    @issue_identifier = issue_identifier
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
end
