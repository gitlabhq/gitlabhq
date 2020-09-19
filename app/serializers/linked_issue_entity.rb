# frozen_string_literal: true

class LinkedIssueEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :confidential, :title

  expose :assignees, using: UserEntity

  expose :state

  expose :milestone, using: API::Entities::Milestone

  expose :weight

  expose :reference do |link|
    link.to_reference(issuable.project)
  end

  expose :path do |link|
    project_issue_path(link.project, link.iid)
  end

  expose :relation_path

  expose :due_date, :created_at, :closed_at

  private

  def current_user
    request.current_user
  end

  def issuable
    request.issuable
  end
end
