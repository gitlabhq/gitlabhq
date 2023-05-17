# frozen_string_literal: true

require_relative 'base'

class CreateIssue < Base
  def execute(issue_data)
    client.create_issue(project, issue_data.delete(:title), issue_data)
  end
end
