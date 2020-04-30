# frozen_string_literal: true

class IssuesChannel < ApplicationCable::Channel
  def subscribed
    project = Project.find_by_full_path(params[:project_path])
    return reject unless project

    issue = project.issues.find_by_iid(params[:iid])
    return reject unless issue && Ability.allowed?(current_user, :read_issue, issue)

    stream_for issue
  end
end
