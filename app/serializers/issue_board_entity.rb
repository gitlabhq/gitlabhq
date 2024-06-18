# frozen_string_literal: true

class IssueBoardEntity < Grape::Entity
  include RequestAwareEntity

  format_with(:upcase) do |item|
    item.try(:upcase)
  end

  expose :id
  expose :iid
  expose :title

  expose :confidential
  expose :due_date
  expose :project_id
  expose :relative_position
  expose :time_estimate
  expose :closed do |issue|
    issue.closed?
  end

  expose :project do |issue|
    API::Entities::Project.represent issue.project, only: [:id, :path, :path_with_namespace]
  end

  expose :milestone, if: ->(issue) { issue.milestone } do |issue|
    API::Entities::Milestone.represent issue.milestone, only: [:id, :title]
  end

  expose :assignees do |issue|
    API::Entities::UserBasic.represent issue.assignees, only: [:id, :name, :username, :avatar_url]
  end

  expose :labels do |issue|
    LabelEntity.represent issue.labels, project: issue.project, only: [:id, :title, :description, :color, :priority, :text_color]
  end

  expose :reference_path, if: ->(issue) { issue.project } do |issue, options|
    options[:include_full_project_path] ? issue.to_reference(full: true) : issue.to_reference
  end

  expose :real_path, if: ->(issue) { issue.project } do |issue|
    Gitlab::UrlBuilder.build(issue, only_path: true)
  end

  expose :issue_sidebar_endpoint, if: ->(issue) { issue.project } do |issue|
    project_issue_path(issue.project, issue, format: :json, serializer: 'sidebar_extras')
  end

  expose :toggle_subscription_endpoint, if: ->(issue) { issue.project } do |issue|
    toggle_subscription_project_issue_path(issue.project, issue)
  end

  expose :assignable_labels_endpoint, if: ->(issue) { issue.project } do |issue|
    project_labels_path(issue.project, format: :json, include_ancestor_groups: true)
  end

  expose :issue_type,
    as: :type,
    format_with: :upcase,
    documentation: { type: "String", desc: "One of #{::WorkItems::Type.base_types.keys.map(&:upcase)}" }
end

IssueBoardEntity.prepend_mod_with('IssueBoardEntity')
