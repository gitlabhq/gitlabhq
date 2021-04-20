# frozen_string_literal: true

class ExternalIssue
  include Referable

  attr_reader :project

  def initialize(issue_identifier, project)
    @issue_identifier = issue_identifier
    @project = project
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

  def project_id
    project.id
  end

  def to_reference(_from = nil, full: nil)
    reference_link_text
  end

  def reference_link_text(from = nil)
    return "##{id}" if id =~ /^\d+$/

    id
  end

  def notes
    Note.none
  end
end
