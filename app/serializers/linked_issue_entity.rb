# frozen_string_literal: true

class LinkedIssueEntity < Grape::Entity
  include RequestAwareEntity

  format_with(:upcase) do |item|
    item.try(:upcase)
  end

  expose :id, :iid, :confidential, :title

  expose :assignees, using: UserEntity

  expose :state

  expose :milestone, using: API::Entities::Milestone

  expose :weight

  expose :reference do |link|
    link.to_reference(issuable.project)
  end

  expose :path do |link|
    Gitlab::UrlBuilder.build(link, only_path: true)
  end

  expose :issue_type,
    as: :type,
    format_with: :upcase,
    documentation: { type: "String", desc: "One of #{::WorkItems::Type.base_types.keys.map(&:upcase)}" }

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
