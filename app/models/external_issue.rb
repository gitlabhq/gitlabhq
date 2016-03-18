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

  def project
    @project
  end

  # Pattern used to extract `JIRA-123` issue references from text
  def self.reference_pattern
    %r{(?<issue>\b([A-Z][A-Z0-9_]+-)\d+)}
  end

  def to_reference(_from_project = nil)
    id
  end
end
