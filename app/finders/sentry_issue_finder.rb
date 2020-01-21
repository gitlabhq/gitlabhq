# frozen_string_literal: true

class SentryIssueFinder
  attr_accessor :project, :current_user

  def initialize(project, current_user: nil)
    @project = project
    @current_user = current_user
  end

  def execute(identifier)
    return unless authorized?

    SentryIssue
      .for_project_and_identifier(project, identifier)
  end

  private

  def authorized?
    Ability.allowed?(current_user, :read_sentry_issue, project)
  end
end
